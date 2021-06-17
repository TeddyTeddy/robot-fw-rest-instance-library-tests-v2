*** Settings ***
Documentation		Implements keywords for /db endpoint
Library				REST		${API_BASE_URL}

*** Keywords ***
Fetch From Database
	[Documentation]		Fetches the resources list for the given resource_name (e.g. posts)
	[Arguments]			${resource_name}
	GET			/db
	${resources_list} =		Output		response body ${resource_name}
	[Return]		${resources_list}

Get Number of Posts
	[Documentation]		Returns the number of posts in the database
	${posts} = 			Fetch From Database 	posts
	${number_of_posts} =  Get Length	${posts}
	[Return]	${number_of_posts}

Fetch Posts From Database
	[Documentation]		If start_index and end_index are provided, returns the posts
	... 				from the database starting with page_start_index
	...					and ending with page_end_index. Otherwise returns all the posts in the database
	[Arguments]		${start_index}=${EMPTY}		${end_index}=${EMPTY}
	${posts} = 		Fetch From Database 	posts
	${is_range_provided} = 		Evaluate	$start_index!='' and $end_index!=''
	IF	${is_range_provided}
		${posts} =		Evaluate		$posts[$start_index:$end_index]
	END
	[Return]		${posts}