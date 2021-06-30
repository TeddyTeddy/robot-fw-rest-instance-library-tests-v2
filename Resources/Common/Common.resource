*** Settings ***
Documentation		add documentation here
Library				OperatingSystem
Library				Collections
Library				Utilities
Library				Process


*** Variable ***
${DEFAULT_PAGE_LIMIT}		${10}
${API_BASE_URL}				http://localhost:3000/
# For "Calculate Link Header With Limit Included" keyword
${LINK_HEADER_TEMPLATE_1}	<${API_BASE_URL}posts?_page=1&_limit={limit}>; rel="first", <${API_BASE_URL}posts?_page={next_page}&_limit={limit}>; rel="next", <${API_BASE_URL}posts?_page={last_page_index}&_limit={limit}>; rel="last"
${LINK_HEADER_TEMPLATE_2}	<${API_BASE_URL}posts?_page=1&_limit={limit}>; rel="first", <${API_BASE_URL}posts?_page={previous_page}&_limit={limit}>; rel="prev", <${API_BASE_URL}posts?_page={last_page_index}&_limit={limit}>; rel="last"
${LINK_HEADER_TEMPLATE_3}	<${API_BASE_URL}posts?_page=1&_limit={limit}>; rel="first", <${API_BASE_URL}posts?_page={previous_page}&_limit={limit}>; rel="prev", <${API_BASE_URL}posts?_page={next_page}&_limit={limit}>; rel="next", <${API_BASE_URL}posts?_page={last_page_index}&_limit={limit}>; rel="last"
# For "Calculate Link Header Without Limit Included" keyword
${LINK_HEADER_TEMPLATE_4}	<${API_BASE_URL}posts?_page=1>; rel="first", <${API_BASE_URL}posts?_page={next_page}>; rel="next", <${API_BASE_URL}posts?_page={last_page_index}>; rel="last"
${LINK_HEADER_TEMPLATE_5}	<${API_BASE_URL}posts?_page=1>; rel="first", <${API_BASE_URL}posts?_page={previous_page}>; rel="prev", <${API_BASE_URL}posts?_page={last_page_index}>; rel="last"
${LINK_HEADER_TEMPLATE_6}	<${API_BASE_URL}posts?_page=1>; rel="first", <${API_BASE_URL}posts?_page={previous_page}>; rel="prev", <${API_BASE_URL}posts?_page={next_page}>; rel="next", <${API_BASE_URL}posts?_page={last_page_index}>; rel="last"


*** Keywords ***
Stop Server
	Terminate All Processes

Re-Start Server
	${rc}	${pids} =		Run And Return Rc And Output	pgrep -f 'node server.js --watch db.json'
	${is_not_empty} =		Evaluate	$pids!=''
	IF	${is_not_empty}
		${pids} = 	Evaluate	$pids.split('\\n')
		FOR  ${pid}		IN		@{pids}
			Run		kill ${pid}
		END
	END
	Start Process		node server.js --watch db.json	shell=True	alias=json-server-process	cwd=${EXECDIR}
	Sleep 	1.5s		# allow JSONSERVER to reboot itself
	# ${pid} = 			Get Process Id		handle=json-server-process
	# Log To Console		\njson-server-process id:${pid}

Restore Database
	[Documentation]			By checking out the stored version of the db.json, we revert the effects of CRUD requests
	...						in the test cases. Note that JSONSERVER listens to the changes in db.json, it re-starts
	...						each time db.json is updated.
	${rc} =	 				Run And Return Rc			git checkout db.json
	Should Be Equal			${rc}		${0}

Contains Sub Dictionary
	[Documentation]		Expects resource_one as dictionary like, turns it into a Python dictionary
	...					Expects resource_two as a string representation of a dictionary,
	...					converts it into a Python dictionary
	...					If resource_one contains the subdictionary resource_two, then it passes
	...					otherwise it fails
	[Arguments]		${resource_one}			${resource_two}
	${resource_one} =	 Convert To Dictionary		${resource_one}
	${resource_two} =	 Evaluate		eval($resource_two)
	Dictionary Should Contain Sub Dictionary	${resource_one}		${resource_two}

Calculate Link Header
	[Arguments]			${pages}	${current_page_index}	${limit}

	Log		${pages}
	Log		${current_page_index}
	Log		${limit}

	IF	${limit}==${DEFAULT_PAGE_LIMIT}
		${link_header} = 	Calculate Link Header Without Limit Included	${pages}	${current_page_index}
	ELSE
		${link_header} = 	Calculate Link Header With Limit Included	${pages}	${current_page_index}	${limit}
	END

	[Return]	${link_header}

Calculate Link Header With Limit Included
	[Arguments]			${pages}	${current_page_index}	${limit}
	# note that first_page_index is always one
	${first_page_index} =		Evaluate		$pages[0]
	${last_page_index} =		Evaluate		$pages[len($pages)-1]

	IF  ${first_page_index}==${last_page_index}
		# regardless of ${current_page_index} (e.g. /posts?_page=20&_limit=200) where total number of posts is e.g. 100
		# Link header must be empty
		${link_header} = 	Set Variable	${EMPTY}
	ELSE IF		${first_page_index}!=${last_page_index} and ${current_page_index}==1
		${link_header} = 	Evaluate	$LINK_HEADER_TEMPLATE_1.format(limit=$limit, next_page=2, last_page_index=$last_page_index)
	ELSE IF 	${first_page_index}!=${last_page_index} and ${current_page_index}==${last_page_index}
		${link_header} = 	Evaluate	$LINK_HEADER_TEMPLATE_2.format(limit=$limit, previous_page=$current_page_index-1, last_page_index=$last_page_index)
	ELSE
		${link_header} = 	Evaluate	$LINK_HEADER_TEMPLATE_3.format(limit=$limit, previous_page=$current_page_index-1, next_page=$current_page_index+1, last_page_index=$last_page_index)
	END
	[Return]	${link_header}

Calculate Link Header Without Limit Included
	[Arguments]			${pages}	${current_page_index}
	# note that first_page_index is always one
	${first_page_index} =		Evaluate		$pages[0]
	${last_page_index} =		Evaluate		$pages[len($pages)-1]

	IF  ${first_page_index}==${last_page_index}
		# regardless of ${current_page_index} (e.g. /posts?_page=20&_limit=200)  where total number of posts is e.g. 100
		# Link header must be empty
		${link_header} = 	Set Variable	${EMPTY}
	ELSE IF		${first_page_index}!=${last_page_index} and ${current_page_index}==1
		${link_header} = 	Evaluate	$LINK_HEADER_TEMPLATE_4.format(next_page=2, last_page_index=$last_page_index)
	ELSE IF 	${first_page_index}!=${last_page_index} and ${current_page_index}==${last_page_index}
		${link_header} = 	Evaluate	$LINK_HEADER_TEMPLATE_5.format(previous_page=$current_page_index-1, last_page_index=$last_page_index)
	ELSE
		${link_header} = 	Evaluate	$LINK_HEADER_TEMPLATE_6.format(previous_page=$current_page_index-1, next_page=$current_page_index+1, last_page_index=$last_page_index)
	END
	[Return]	${link_header}

Filter In Resource List By
	[Documentation]		Given a list of resources, which are dictionaries, this keyword returns the resources
	...					having field_name with field_value
	[Arguments]			${resources_list}		${field_name}		${field_value}
	FOR		${resource}		IN 		@{resources_list}
		${is_match} = 		Evaluate	$field_name in $resource and $resource[$field_name]==$field_value
		IF	not ${is_match}
			${index} = 		Get Index From List		${resources_list}		${resource}
			Remove From List	${resources_list}	${index}
		END
	END

Filter Out Resource List By
	[Documentation]		Given a list of resources, which are dictionaries, this keyword returns the resources
	...					NOT having field_name with field_value
	[Arguments]			${resources_list}		${field_name}		${field_value}
	FOR		${resource}		IN 		@{resources_list}
		${is_match} = 		Evaluate	$field_name in $resource and $resource[$field_name]==$field_value
		IF 	${is_match}
			${index} = 		Get Index From List		${resources_list}		${resource}
			Remove From List	${resources_list}	${index}
		END
	END

Pick A Random Title Keyword
	[Documentation]			Picks a random post from the given list of posts
	...						Then picks a random keyword from the post's title
	[Arguments]			${posts}
	${length} = 				Get Length		${posts}
	IF		${length}>0
		${index} = 					Evaluate 	random.randint(0, $length-1)  	modules=random
		${random_post} =			Evaluate	$posts[$index]
		${title} =					Evaluate	$random_post['title']
		${title_keywords} = 		Evaluate	re.split(r' ', $title)		modules=re
		${title_keywords_length} = 	Get Length		${title_keywords}
		${index} = 					Evaluate 	random.randint(0, $title_keywords_length-1)  	modules=random
		${random_title_keyword} =	Evaluate	$title_keywords[$index]
	ELSE
		${random_title_keyword} = 	Set Variable	${EMPTY}
	END
	[Return]	${random_title_keyword}

Filter In Resource List Using Like
	[Documentation]		Given a list of resources, which are dictionaries, this keyword returns the resources
	...					having field_name containing a field_value. For example field_name can be title and
	...					field_value can be "lorem". All resources having "lorem" in title will be returned.
	[Arguments]			${resources_list}		${field_name}		${field_value}
	# result is an empty list at the beginning
	FOR		${resource}		IN 		@{resources_list}
		${is_match} = 		Evaluate	bool(re.search(r'\\.*${field_value}\\.*', $resource[$field_name]))		modules=re
		IF	not ${is_match}
			${index} = 		Get Index From List		${resources_list}		${resource}
			Remove From List	${resources_list}	${index}
		END
	END