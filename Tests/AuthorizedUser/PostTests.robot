*** Settings ***
Documentation		All test cases are atomic: after the test execution, they must leave the
...					system in the same state before the execution. To accomplish atomic tests,
...					the test teardown method Restore Database gets called. This restores the
...					backend server's database to initial state before the test execution.
...					When we talk about the term "resource", we mean the post resource in the server
...					Documentaion for the API can be found at https://github.com/typicode/json-server

Resource			${EXECDIR}${/}Resources${/}Common${/}Common.resource
Resource			${EXECDIR}${/}Resources${/}Posts.resource
Resource			${EXECDIR}${/}Resources${/}Database.resource

Suite Setup			Run Keywords	Restore Database	Re-Start Server		Fetch Number Of Posts	Get Random Post From Database	Stop Server
Test Setup			Run Keywords	Restore Database	Re-Start Server		Check Database State
Test Teardown		Run Keywords	Stop Server		Restore Database


*** Variable ***
${NEW_POST_ID}				Value to be set dynamically
${JSON_POST}				{"userId":1,"title":"First blog post","body":"Body content"}
${MODIFIED_JSON_POST}
${NEW_USER_ID}				${2}
${NEW_TITLE}				Modified Title
${NEW_BODY}					Modified Body
${TAGS}						tag1 tag2 tag3

*** Keywords ***
Check Database State
	${number_of_posts} = 	Get Number of Posts
	Should Be Equal		${number_of_posts}		${100}

Fetch Number Of Posts
	# total is 100 with the current db.json, but it can change if we change the db.json
	${NUMBER_OF_POSTS} = 	Get Number of Posts
	Set Suite Variable		${NUMBER_OF_POSTS}

Get Random Post From Database
	&{EXPECTED_POST} = 		Fetch Random Post From Database
	Set Suite Variable		${EXPECTED_POST}

Test Getting Posts With Pagination
	[Documentation]			limit stands for the number of posts in a given page
	...						total stands for the number of posts in the database
	...						A page contains a list of posts returned by GET /posts?_page=${p}&_limit=${limit}.
	...						Part One:
	...						Given the limit and total, we calculate pages_with_posts
	...						For each p in pages_with_posts, We do the following:
	...							- Fetch expected_posts from the database directly
	...						    - Calculate the expected Link header content.
	...						    - Make a test call to an API (i.e. GET /posts?_page=${p}&_limit=${limit})
	...						      and store the outcome as observed_posts and observed_link_header.
	...						    - Compare expected_posts to observed_posts.
	...							- Compare observed_link_header to expected_link_header
	...
	...						Part Two:
	...							- Given pages_with_posts, we calculate pages_without_posts
	...						For each p in pages_without_posts, we do the following:
	...							- Make a test call to API (i.e. GET /posts?_page=${p}&_limit=${limit})
	...							  and store the outcome as observed_posts and observed_link_header
	...						    - Compare observed_posts to and empty list.
	...							- Compare observed_link_header to an empty string
	[Arguments]		${limit}

	# limit stands for the number of posts in a given page
	Log		${limit}
	# total stands for the number of posts in the database
	${total} = 					Set Variable	${NUMBER_OF_POSTS}
	# Part One
	# pages_with_posts is a list containing page numbers based on a given limit and total
	# note that the numbered pages are supposed to contain posts
	${pages_with_posts} = 		Get Page Set	${total}	${limit}

	FOR  ${p}	IN   @{pages_with_posts}
		${page_start_index} =		Evaluate		$limit*($p-1)
		${page_end_index} =			Evaluate		$limit*$p
		${expected_posts} =			Fetch Posts From Database	${page_start_index}		${page_end_index}
		${expected_link_header} =	Calculate Link Header		${pages_with_posts}		${p}	${limit}
		# test call
		${observed_posts} 	${observed_link_header} =		Get Posts With Pagination	${p}	${limit}
		Should Be Equal		${expected_posts}		${observed_posts}
		Should Be Equal		${expected_link_header}		${observed_link_header}
	END

	# Part Two
	# pages_without_posts is a list of the pages that are not supposed to contain posts
	# pages_without_posts is calculated based on pages_with_posts
	# The rule is that pages_without_posts must not contain any page included in pages_with_posts
	${pages_without_posts} = 	Get Empty Pages		${pages_with_posts}
	# expected_posts is an empty list
	${expected_posts} =			Create List
	# expected_link_header is an empty header
	${expected_link_header} =	Set Variable	${EMPTY}

	FOR  ${p}	IN   @{pages_without_posts}
		# test call
		${observed_posts} 	${observed_link_header} =		Get Posts With Pagination	${p}	${limit}
		Should Be Equal		${expected_posts}		${observed_posts}
		Should Be Equal		${expected_link_header}		${observed_link_header}
	END


*** Test Case ***
Creating Post
	[Documentation]			Creates a new post with JSON_POST (1) and retrives its id and the new post itself (2)
	...						A) Checks that (2) contains all the key/value pairs in (1).
	...						B) With the id, it reads the post once again (3) and compares
	...						(3) with (2). They must match exactly.
	[Tags]		create-tested		read
	# test call: create a new post
	${new_post_id}		${new_post} = 	Create Post		${JSON_POST}

	# A) verify that ${new_post} content contains the items from ${JSON_POST}
	Contains Sub Dictionary			${new_post}		${JSON_POST}

	# B) verify that what is created can indeed be retrived too
	${post_read} = 		Get Post With Id	${new_post_id}
	Should Be Equal		${new_post}		${post_read}

Reading All Posts
	[Documentation]			Reads all the post resources and compares that with what database has
	[Tags]		read-tested
	# test call
	${all_posts} = 		Read All Posts

	# verify posts against database
	${posts_directly_from_db} =	Fetch From Database		posts
	Should Be Equal		${all_posts}		${posts_directly_from_db}

Reading Post By Id
	[Documentation]			Reads an existing post from the server. Compares the post read with the expected post
	[Tags]		read-tested
	# test call
	${observed_post} = 		Get Post With Id	${EXPECTED_POST}[id]
	# verify
	Should Be Equal		${observed_post}		${EXPECTED_POST}

Reading Post By Filtering Id
	[Documentation]			Reads posts by providing a filter containing a id value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?id=${EXPECTED_POST}[id]
	# test call
	${post_list} = 			Get Posts With Filter	${filter}
	# verify
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST}		${post_list}[0]

Reading Post By Filtering Title
	[Documentation]			Reads posts by providing a filter containing a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?title=${EXPECTED_POST}[title]
	# test call
	${post_list} = 			Get Posts With Filter	${filter}
	# verify
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST}		${post_list}[0]

Reading Post By Filtering Id & Title
	[Documentation]			Reads posts by providing a filter containing an id value and a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?id=${EXPECTED_POST}[id]&title=${EXPECTED_POST}[title]
	# test call
	${post_list} = 			Get Posts With Filter	${filter}
	# verify
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST}		${post_list}[0]

Reading Post By Filtering UserId And Title
	[Documentation]			Reads posts by providing a filter containing a userId value and a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?userId=${EXPECTED_POST}[userId]&title=${EXPECTED_POST}[title]
	${post_list} = 			Get Posts With Filter	${filter}
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST}		${post_list}[0]

Reading Post By Filtering UserId, Id And Title
	[Documentation]			Reads posts by providing a filter containing a userId value, id value and a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?userId=${EXPECTED_POST}[userId]&id=${EXPECTED_POST}[id]&title=${EXPECTED_POST}[title]
	${post_list} = 			Get Posts With Filter	${filter}
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST}		${post_list}[0]

Reading Post By Filtering UserId And Id
	[Documentation]			Reads posts by providing a filter containing a userId value and an id value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?userId=${EXPECTED_POST}[userId]&id=${EXPECTED_POST}[id]
	${post_list} = 			Get Posts With Filter	${filter}
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST}		${post_list}[0]

Updating Post UserId
	[Documentation]			Creates a post with JSON_POST (1) and updates its "userId" locally
	...						by calling Update Post UserId, which
	...						then makes a PUT request updating the resource in the server.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}

	Set To Dictionary		${expected_post}		userId=${NEW_USER_ID}
	# test call: update the post with post_id
	Update Post			${post_id}		${expected_post}
	# expected_post got updated with "userId"=${NEW_USER_ID}
	Verify Post Updated			${post_id}		${expected_post}


Updating Post Title
	[Documentation]			Creates a post with JSON_POST (1) and updates its "title" locally
	...						by calling Update Post Title, which
	...						then makes a PUT request updating the resource in the server.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}

	Set To Dictionary		${expected_post}		title=${NEW_TITLE}
	# test call: update the post with post_id
	Update Post			${post_id}		${expected_post}
	# expected_post got updated with "title"=${NEW_TITLE}
	Verify Post Updated		${post_id}		${expected_post}

Updating Post Body
	[Documentation]			Creates a post with JSON_POST (1) and updates its "body" item locally
	...						by calling Update Post Body, which
	...						then makes a PUT request updating the resource in the server.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}

	# expected_post gets its body updated with NEW_BODY
	Set To Dictionary		${expected_post}		body=${NEW_BODY}
	# test call: update the post with post_id
	Update Post			${post_id}		${expected_post}
	# expected_post got updated with "body"=${NEW_BODY}
	Verify Post Updated		${post_id}		${expected_post}

Updating Post UserId & Title
	[Documentation]			Creates a post with JSON_POST (1) and updates its "title" and "userId" items locally
	...						Then uses the local post to update the one in the server via Updating Post keyword.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Set To Dictionary		${expected_post}		userId=${NEW_USER_ID}
	Set To Dictionary		${expected_post}		title=${NEW_TITLE}
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Updating Post Title & Body
	[Documentation]			Creates a post with JSON_POST (1) and updates its "title" and "body" items locally
	...						Then uses the local post to update the one in the server via Update Post keyword.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Set To Dictionary		${expected_post}		title=${NEW_TITLE}
	Set To Dictionary		${expected_post}		body=${NEW_BODY}
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Updating Post UserId & Body
	[Documentation]			Creates a post with JSON_POST (1) and updates its "userId" and "body" items locally
	...						Then uses the local post to update the one in the server via Update Post keyword.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Set To Dictionary		${expected_post}		userId=${NEW_USER_ID}
	Set To Dictionary		${expected_post}		body=${NEW_BODY}
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Updating All Fields Except Id In Post
	[Documentation]			Creates a post with JSON_POST (1) and updates its "userId", "title" and "body" locally
	...						Then uses the local post to update the one in the server via Update Post keyword.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Set To Dictionary		${expected_post}		userId=${NEW_USER_ID}
	Set To Dictionary		${expected_post}		title=${NEW_TITLE}
	Set To Dictionary		${expected_post}		body=${NEW_BODY}
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Attempting To Update Id In Post
	[Documentation]			Acc.to the API documentation, Id values are not mutable.
	...						Any id value in the body of your PUT request will be ignored
	...						Creates a post with JSON_POST (1) and updates its "userId", "title", "body" and "id" locally
	...						Then uses the local post to update the one in the server via Update Post keyword.
	...						Checks that the post resource got only "userId", "title" and "body" updated.
	...						Checks that "id" did not change in the post resource.
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Set To Dictionary		${expected_post}		userId=${NEW_USER_ID}
	Set To Dictionary		${expected_post}		title=${NEW_TITLE}
	Set To Dictionary		${expected_post}		body=${NEW_BODY}
	${new_post_id} =		Evaluate	$post_id+1
	Set To Dictionary		${expected_post}		id=${new_post_id}
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	# Checks that "id" did not change in the post resource
	${expected_error} = 	Set Variable	{'userId': ${NEW_USER_ID}, 'title': '${NEW_TITLE}', 'body': '${NEW_BODY}', 'id': ${new_post_id}} != {'userId': ${NEW_USER_ID}, 'title': '${NEW_TITLE}', 'body': '${NEW_BODY}', 'id': ${post_id}}
	Run Keyword And Expect Error	${expected_error} 		Verify Post Updated		${post_id}		${expected_post}
	# Checks that "id" did not change in the post resource
	Set To Dictionary		${expected_post}		id=${post_id}
	Verify Post Updated		${post_id}		${expected_post}

Add Additional Tags Field To Post
	[Documentation]			Creates a post with JSON_POST (1) and adds "tags" field locally
	...						Then uses the local post to update the one in the server via Update Post keyword.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Set To Dictionary		${expected_post}		tags=${TAGS}
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Attempting To Remove All Fields Including Id In Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post title,
	...						we can provide a JSON with no title field in it. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no title.
	...						This test creates a post with JSON_POST (1) and then updates it with
	...						the one which has no fields. Then test checks that
	...						the post resource in the server got updated with the id unremoved and the rest
	...						of the fields are removed.
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		title
	Remove From Dictionary		${expected_post}		body
	Remove From Dictionary		${expected_post}		userId
	Remove From Dictionary		${expected_post}		id
	Log		Expected post got locally modified: ${expected_post}
	# test call: atttempt to update the post resource in the server with an empty JSON
	Update Post		${post_id}		${expected_post}
	Run Keyword And Expect Error		{} != {'id': ${post_id}}	Verify Post Updated		${post_id}		${expected_post}
	# update expected_post locally
	Set To Dictionary			${expected_post}		id=${post_id}
	# verify that post resource has only id field with post_id value
	Verify Post Updated		${post_id}		${expected_post}

Removing All Fields Except Id In Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post title,
	...						we can provide a JSON with no title field in it. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no title.
	...						This test creates a post with JSON_POST (1) and then updates it with
	...						the one which only have id field. Then test checks that
	...						the post resource in the server got updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		title
	Remove From Dictionary		${expected_post}		body
	Remove From Dictionary		${expected_post}		userId
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Removing Title From Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post title,
	...						we can provide a JSON with no title field in it. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no title.
	...						This test creates a post with JSON_POST (1) and then updates it with
	...						the one which only have title field removed and other fields untouched.
	...						Then test checks that the post resource in the server got updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		title
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Removing Body From Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post body,
	...						we can provide a JSON with no body field in it. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no body.
	...						This test creates a post with JSON_POST (1) and then updates it with
	...						the one which only have body field removed and the other fields untouched.
	...						Then test checks that the post resource in the server got updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		body
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Removing UserId From Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post userId,
	...						we can provide a JSON with no userId field in it. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no userId.
	...						This test creates a post with JSON_POST (1) and then updates it with
	...						the one which only have userId field removed and the other fields untouched.
	...						Then test checks that the post resource in the server got updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		userId
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Removing Title And Body In Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post title and body,
	...						we can provide a JSON with those fields not present. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no title or body.
	...						This test creates a post with JSON_POST (1) and then updates the resource with
	...						the one which doesn't have those fields. Then test checks that
	...						the post resource in the server got updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		title
	Remove From Dictionary		${expected_post}		body
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Removing Title And UserId In Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post title and userId,
	...						we can provide a JSON with those fields not present. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no title or userId.
	...						This test creates a post with JSON_POST (1) and then updates the resource with
	...						the one which doesn't have those fields. Then test checks that
	...						the post resource in the server got updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		title
	Remove From Dictionary		${expected_post}		userId
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Removing Body And UserId In Post
	[Documentation]			Technically, when we make a PUT request with a provided JSON data,
	...						we can erase all fields (except id) by not providing unwanted key/value pairs
	...						in the provided JSON. For example, if we want to get rid of post body and userId,
	...						we can provide a JSON with those fields not present. Then PUT request must overwrite
	...						the resource in the server with the provided JSON resource having no body or userId.
	...						This test creates a post with JSON_POST (1) and then updates the resource with
	...						the one which doesn't have those fields. Then test checks that
	...						the post resource in the server got updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}
	# note that expected_post is a dictionary

	# update expected_post locally
	Remove From Dictionary		${expected_post}		body
	Remove From Dictionary		${expected_post}		userId
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}


Deleting Post
	[Documentation]			Creates a new post with JSON_POST (1) and retrives its id and the new post itself (2)
	...						Deletes the post with the id and then attempts to retrive the post again.
	...						The return value for the retrival must be an empty dictionary
	[Tags]		create		read	delete-tested

	${post_id}		${post} = 	Create Post		${JSON_POST}

	# test call
	Delete Post With Id		${post_id}

	# The return value for the retrival must be an empty dictionary
	${post_read} = 		Get Post With Id	${post_id}
	${expected_post} =		Evaluate	{}
	Should Be Equal		${expected_post}		${post_read}

Pagination Where Page Limit Exceeds Total Number Of Posts
	[Documentation]		https://developer.atlassian.com/server/confluence/pagination-in-the-rest-api/
	...					limit stands for the number of posts per page (e.g. NUMBER_OF_POSTS + 20)
	...					total stands for the number of posts in the database (i.e. NUMBER_OF_POSTS)
	...					When limit exceeds total, a single page must contain all the posts in the database
	[Tags]	read-tested   pagination
	[Template]			Test Getting Posts With Pagination
	${NUMBER_OF_POSTS + 1}
	${NUMBER_OF_POSTS + 2}
	${NUMBER_OF_POSTS + 3}
	${NUMBER_OF_POSTS + 4}
	${NUMBER_OF_POSTS + 5}
	${NUMBER_OF_POSTS + 10}
	${NUMBER_OF_POSTS + 20}
	${NUMBER_OF_POSTS + 50}
	${NUMBER_OF_POSTS + 100}

Pagination Where Page Limit Equals To Total Number Of Posts
	[Documentation]		https://developer.atlassian.com/server/confluence/pagination-in-the-rest-api/
	...					limit stands for the number of posts per page (i.e. NUMBER_OF_POSTS)
	...					total stands for the number of posts in the database (i.e. NUMBER_OF_POSTS)
	...					When limit equals to total, a single page must contain all the posts in the database
	[Tags]	read-tested   pagination
	[Template]			Test Getting Posts With Pagination
	${NUMBER_OF_POSTS}

Pagination Where Page Limit Is Less Than Total Number Of Posts
	[Documentation]		https://developer.atlassian.com/server/confluence/pagination-in-the-rest-api/
	...					limit stands for the number of posts per page (e.g. 8, 20 or 50)
	...					total stands for the number of posts in the database (i.e. NUMBER_OF_POSTS)
	...					When limit is less than the total, a single page can only contain limit number of the posts
	[Tags]	read-tested   pagination

	${limit_list} =		Evaluate		list(range(1, $NUMBER_OF_POSTS))
	FOR  ${limit} 	IN 		@{limit_list}
		Test Getting Posts With Pagination		${limit}
	END

Sorting Posts By Id In Ascending Order
	[Documentation]		Upon GET /posts?_sort=id&_order=asc  we should get a list of posts sorted by id
	...					in ascending order. We compare the the list with the one we fetch & sort from the database
	[Tags]	read-tested 	sorting

	${expected_posts} =		Fetch Posts From Database
	${expected_posts} =		Sort Resource List		${expected_posts}	id	asc
	# test call
	${observed_posts} =		Get Posts By Id In Ascending Order
	Should Be Equal		${expected_posts}		${observed_posts}

Sorting Posts By Id In Descending Order
	[Documentation]		Upon GET /posts?_sort=id&_order=desc  we should get a list of posts sorted by id
	...					in descending order. We compare the the list with the one we fetch & sort from the database
	[Tags]	read-tested 	sorting

	${expected_posts} =		Fetch Posts From Database
	${expected_posts} =		Sort Resource List		${expected_posts}	id	desc
	# test call
	${observed_posts} =		Get Posts By Id In Descending Order
	Should Be Equal		${expected_posts}		${observed_posts}

Sorting Comments For A Specific Post By Id In Descending Order
	[Documentation]		Upon GET /posts/1/comments?_sort=id&_order=desc, we should get a list of comments
	...					belonging to post with id=1 which are sorted by comment id in descending order
	[Tags]	read-tested 	sorting		run-me-only

	${post_id} =			Set Variable		${1}
	${expected_comments} =	Fetch Comments from Database   ${post_id}	id	desc
	# test call
	${observed_comments} =	Get Comments For A Specific Post 	${post_id}	id	desc
	Should Be Equal			${expected_comments}		${observed_comments}


Sorting Comments For A Specific Post By Id In Ascending Order
	[Documentation]		Upon GET /posts/1/comments?_sort=id&_order=asc, we should get a list of comments
	...					belonging to post with id=1 which are sorted by comment id in ascending order
	[Tags]	read-tested 	sorting

	${post_id} =			Set Variable		${1}
	${expected_comments} =	Fetch Comments from Database   ${post_id}	id	asc
	# test call
	${observed_comments} =	Get Comments For A Specific Post 	${post_id}	id	asc
	Should Be Equal			${expected_comments}		${observed_comments}

Sorting Comments For A Specific Post By Id (Asc) And By Email (Asc)
	[Documentation]		Referring to the API documentation:
	...					For sorting with multiple fields, use the following format:
	...					GET 	/posts/1/comments?_sort=id,email&_order=asc,asc
	...					This test case make the above API call and retrive the observed comments.
	...					Then it will fetch the expected comments directly from database
	...				    and sort them first by id (asc) and then by email (asc).
	...					Then it will compare the observed comments with the expected comments
	[Tags]	read-tested 	sorting

	${post_id} =			Set Variable		${1}
	# TODO: expected_comments may need to be different than what the keyword returns. Needs clarification by the API developer
	${expected_comments} =	Fetch Ordered Comments From Database For A Given PostId Ordered By Given Fields
	...						${post_id}		id		asc	  	email	asc
	# test call
	${observed_comments} =	Get Comments For A Specific Post 	${post_id}	id		asc		email	asc
	Should Be Equal			${expected_comments}		${observed_comments}

Sorting Comments For A Specific Post By Id (Desc) And By Email (Asc)
	[Documentation]		Referring to the API documentation:
	...					For sorting with multiple fields, use the following format:
	...					GET 	/posts/1/comments?_sort=id,email&_order=desc,asc
	...					This test case make the above API call and retrive the observed comments.
	...					Then it will fetch the expected comments directly from database
	...				    and sort them first by id (desc) and then by email (asc).
	...					Then it will compare the observed comments with the expected comments
	[Tags]	read-tested 	sorting

	${post_id} =			Set Variable		${1}
	# TODO: expected_comments may need to be different than what the keyword returns. Needs clarification by the API developer
	${expected_comments} =	Fetch Ordered Comments From Database For A Given PostId Ordered By Given Fields
	...						${post_id}		id		desc	  	email	asc
	# test call
	${observed_comments} =	Get Comments For A Specific Post 	${post_id}	id		desc		email	asc
	Should Be Equal			${expected_comments}		${observed_comments}

Sorting Comments For A Specific Post By Id (Asc) And By Email (Desc)
	[Documentation]		Referring to the API documentation:
	...					For sorting with multiple fields, use the following format:
	...					GET 	/posts/1/comments?_sort=id,email&_order=asc,desc
	...					This test case make the above API call and retrive the observed comments.
	...					Then it will fetch the expected comments directly from database
	...				    and sort them first by id (asc) and then by email (desc).
	...					Then it will compare the observed comments with the expected comments
	[Tags]	read-tested 	sorting

	${post_id} =			Set Variable		${1}
	# TODO: expected_comments may need to be different than what the keyword returns. Needs clarification by the API developer
	${expected_comments} =	Fetch Ordered Comments From Database For A Given PostId Ordered By Given Fields
	...						${post_id}		id		asc	  	email	desc
	# test call
	${observed_comments} =	Get Comments For A Specific Post 	${post_id}	id		asc		email	desc
	Should Be Equal			${expected_comments}		${observed_comments}

Sorting Comments For A Specific Post By Id (Desc) And By Email (Desc)
	[Documentation]		Referring to the API documentation:
	...					For sorting with multiple fields, use the following format:
	...					GET 	/posts/1/comments?_sort=id,email&_order=desc,desc
	...					This test case make the above API call and retrive the observed comments.
	...					Then it will fetch the expected comments directly from database
	...				    and sort them first by id (desc) and then by email (desc).
	...					Then it will compare the observed comments with the expected comments
	[Tags]	read-tested 	sorting

	${post_id} =			Set Variable		${1}
	# TODO: expected_comments may need to be different than what the keyword returns. Needs clarification by the API developer
	${expected_comments} =	Fetch Ordered Comments From Database For A Given PostId Ordered By Given Fields
	...						${post_id}		id		desc	  	email	desc
	# test call
	${observed_comments} =	Get Comments For A Specific Post 	${post_id}	id		desc		email	desc
	Should Be Equal			${expected_comments}		${observed_comments}

Slicing Posts Ten Times With Different Start And End Values
	[Documentation]		Referring to the API documentation:
	...					GET /posts?_start=20&_end=30
	...					where _start is inclusive and _end is exclusive
	...					This test case make the above API call with a random set of _start and _end values
	...					and makes a fetch of expected_posts from database for the same _start and _end.
	...					It then compares the expected_posts with observed_posts. It also calculates the expected length
	...					of observed_posts and compares that with the observed length of observed_posts
	[Tags]	read-tested		slicing

	FOR		${i}	IN RANGE 		10
		# note that start_index starts from zero when posts are fetched from database
		${start_index} =		Evaluate	random.randint(0, $NUMBER_OF_POSTS-1)  	modules=random
		${end_index} =			Evaluate	random.randint($start_index+1, $start_index+$NUMBER_OF_POSTS)  	modules=random
		${expected_posts} =		Fetch Posts From Database	${start_index}		${end_index}

		# note that start_index starts from 0 too when posts are fetched via API call
		# test call
		${observed_posts} =		Get Sliced Posts	${start_index}		${end_index}
		Should Be Equal			${expected_posts}		${observed_posts}
		# note that start_index is between [0, NUMBER_OF_POSTS-1]
		# and end_index is between [start_index+1, start_index+NUMBER_OF_POSTS]
		# we expect observed_posts to be a non-empty list at least containing 1 item
		${observed_length} = 			Get Length				${observed_posts}
		Should Not Be Equal		${0}		${observed_length}
		# calculate expected_length of the observed_posts list
		IF	${end_index} >= ${NUMBER_OF_POSTS}
			${expected_length} =	Evaluate	$NUMBER_OF_POSTS-$start_index
		ELSE
			${expected_length} =	Evaluate	$end_index-$start_index
		END
		Should Be Equal		${expected_length}		${observed_length}
	END

Slicing Posts With All Possible Start And End Combinations
	[Documentation]		Referring to the API documentation:
	...					GET /posts?_start=20&_end=30
	...					where _start is inclusive and _end is exclusive
	...					This test case make the above API call with all possible combinations of _start and _end values.
	...					For each call, the test case fetches expected_posts from database for the same _start and _end.
	...					It then compares the expected_posts with observed_posts. It also calculates the expected length
	...					of observed_posts and compares that with the observed length of observed_posts
	[Tags]	read-tested		slicing

	FOR  ${start_index}		IN RANGE		${0}	${NUMBER_OF_POSTS+10}
		FOR  ${end_index}	IN RANGE		${start_index+1}	${NUMBER_OF_POSTS +11}
			Re-Start Server  # in case server uses caching, re-starting the server will limit the memory usage
			Log To Console	start_index:${start_index}
			Log To Console	end_index:${end_index}
			# note that start_index starts from zero when posts are fetched from database
			${expected_posts} =		Fetch Posts From Database	${start_index}		${end_index}
			# note that start_index starts from 0 too when posts are fetched via API call
			# test call
			${observed_posts} =		Get Sliced Posts	${start_index}		${end_index}
			Should Be Equal			${expected_posts}		${observed_posts}
			# note that start_index is between [0, NUMBER_OF_POSTS-1]
			# and end_index is between [start_index+1, start_index+NUMBER_OF_POSTS]
			# we expect observed_posts to be a non-empty list at least containing 1 item
			${observed_length} = 			Get Length				${observed_posts}
			# calculate expected_length of the observed_posts list
			IF	${end_index} < ${NUMBER_OF_POSTS}
				${expected_length} =	Evaluate	$end_index-$start_index
			ELSE IF	${end_index} >= ${NUMBER_OF_POSTS} and ${start_index} < ${NUMBER_OF_POSTS}
				${expected_length} =	Evaluate	$NUMBER_OF_POSTS-$start_index
			ELSE
				${expected_length} =	Set Variable	${0}
			END
			Should Be Equal		${expected_length}		${observed_length}
			Stop Server		# in case server uses caching, stopping the server will limit the memory usage

		END
	END

Slicing Posts Ten Times With Different Start And Limit Values
	[Documentation]		Referring to the API documentation:
	...					GET /posts?_start=20&_limit=30
	...					where _start is inclusive and _limit indicates the number of posts to be returned.
	...					This test case make the above API call with a random set of _start and _limit values
	...					and fetches expected_posts from database for the same _start and _limit.
	...					It then compares the expected_posts with observed_posts. It also calculates the expected length
	...					of observed_posts and compares that with the observed length of observed_posts
	[Tags]	read-tested		slicing

	FOR		${i}	IN RANGE 		10
		# note that start_index starts from zero when posts are fetched from database
		${start_index} =		Evaluate	random.randint(0, $NUMBER_OF_POSTS-1)  	modules=random
		${limit} =				Evaluate	random.randint(1, $NUMBER_OF_POSTS)  	modules=random
		${end_index} =			Evaluate	$start_index+$limit
		${expected_posts} =		Fetch Posts From Database	${start_index}		${end_index}

		# note that start_index starts from 0 too when posts are fetched via API call
		# test call
		${observed_posts} =		Get Sliced Posts Using Limit		${start_index}		${limit}
		Should Be Equal			${expected_posts}		${observed_posts}
		# note that start_index is between [0, NUMBER_OF_POSTS-1]
		# limit is at least 1. So, we expect observed_posts to be a non-empty list at least containing 1 item
		${observed_length} = 	Get Length				${observed_posts}
		Should Not Be Equal		${0}		${observed_length}
		# calculate expected_length of the observed_posts list
		IF	${end_index} >= ${NUMBER_OF_POSTS}
			${expected_length} =	Evaluate	$NUMBER_OF_POSTS-$start_index
		ELSE
			${expected_length} =	Set Variable	${limit}
		END
		Should Be Equal		${expected_length}		${observed_length}
	END

Slicing Posts With All Possible Start And Limit Combinations
	[Documentation]		Referring to the API documentation:
	...					GET /posts?_start=20&_limit=30
	...					where _start is inclusive and _limit indicates the number of posts to be returned.
	...					_start starts from index 0 (works like Array.slice() in JS)
	...					This test case make the above API call with all possible combinations of _start and _limit values.
	...					For each call, the test case fetches expected_posts from database for the same _start and _limit.
	...					It then compares the expected_posts with observed_posts. It also calculates the expected length
	...					of observed_posts and compares that with the observed length of observed_posts
	[Tags]	read-tested		slicing

	FOR  ${start_index}		IN RANGE		${0}	${NUMBER_OF_POSTS+10}
		FOR  ${limit}		IN RANGE		${1}	${NUMBER_OF_POSTS}
			Re-Start Server  # in case server uses caching, re-starting the server will limit the memory usage
			${end_index} =			Evaluate	$start_index+$limit
			Log To Console	start_index:${start_index}
			Log To Console	end_index:${end_index}
			Log To Console	limit:${limit}
			# note that start_index starts from zero when posts are fetched from database
			${expected_posts} =		Fetch Posts From Database	${start_index}		${end_index}
			# note that start_index starts from 0 too when posts are fetched via API call
			# test call
			${observed_posts} =		Get Sliced Posts Using Limit	${start_index}		${limit}
			Should Be Equal			${expected_posts}		${observed_posts}
			# note that start_index is between [0, NUMBER_OF_POSTS-1]
			# and end_index is between [start_index+1, start_index+NUMBER_OF_POSTS]
			# we expect observed_posts to be a non-empty list at least containing 1 item
			${observed_length} = 			Get Length				${observed_posts}
			# calculate expected_length of the observed_posts list
			IF	${end_index} < ${NUMBER_OF_POSTS}
				${expected_length} =	Set Variable	${limit}
			ELSE IF	${end_index} >= ${NUMBER_OF_POSTS} and ${start_index} < ${NUMBER_OF_POSTS}
				${expected_length} =	Evaluate	$NUMBER_OF_POSTS-$start_index
			ELSE
				${expected_length} =	Set Variable	${0}
			END
			Should Be Equal		${expected_length}		${observed_length}
			Stop Server		# in case server uses caching, stopping the server will limit the memory usage
		END
	END

Fetching Posts Ten Times With Different GTE, LTE And NE Values For Id Field And Different Like Values For Title Field
	[Documentation]			GTE (greater than or equal to) follows the id range [1,inf]
	...						LTE (less than or equal to) has a range [GTE, inf]
	...						NE is a random number between [GTE, LTE]
	...						(1) We fetch the posts, whose id is between [GTE, LTE]
	...						(2) The posts in (1) is filtered such that only the posts whose id is not eqal to NE
	...						stays in the posts list.
	...						(3) Title field for a post (e.g. Lorem ipsum ador) will be searched for a random_title_keyword
	...						If a post contains the random_title_keyword in its title field, only then the post will be
	...						present in expected_posts. Otherwise, the post will be removed from expected_posts.
	...						(4) We make the following call to the API:
	...						GET		/posts?id_gte=${gte}&id_lte=${lte}&id_ne=${ne}&title_like=${like}

	[Tags]	read-tested		operators	gte		lte		ne	like

	FOR  ${i}		IN RANGE		10
		${gte} = 	Evaluate 	random.randint(0, $NUMBER_OF_POSTS-1)  	modules=random
		${lte} =	Evaluate 	random.randint($gte, $NUMBER_OF_POSTS-1)  	modules=random
		${ne} = 	Evaluate 	random.randint($gte, $lte)  	modules=random

		# (1) We fetch the posts, whose id is between [GTE, LTE]
		${expected_posts} =		Fetch Posts From Database With GTE and LTE For A Field		id		${gte}		${lte}
		# (2) expected_posts is modified in place
		Filter Out Resource List By  ${expected_posts}  	id  	${ne}
		${random_title_keyword} = 	Pick A Random Title Keyword		${expected_posts}
		# (3) expected_posts is modified in place
		Filter In Resource List Using Like  ${expected_posts}  title 	${random_title_keyword}
		# at this point, expected_posts does represent what we must see from the API call
		# (4) Now we can make the test call
		${observed_posts}= 		Get Posts With GTE, LTE And NE Values For Field Name One and Like Values For Field Name Two
		...		id		${gte}		${lte}		${ne}		title		${random_title_keyword}
		Should Be Equal			${expected_posts}		${observed_posts}
	END

Fetching All Posts With Their Comments Via Embed
	[Documentation]			Referring to the API documentation:
	...						GET /posts/?_embed=comments
	...						This API call returns all the post resources with their respective comments.
	...						For each post, there is a comments item having a list of comments.
	...						(1) This test case fetches the expected_posts with id from database along with their respective comments
	...						(2) It makes the API call returning observed_posts with their respective comments
	...						Then this test case compare the observed_posts with the expected_posts
	[Tags]	read-tested		embed
	# (1)
	${expected_posts} = 	Create List
	FOR  ${id}		IN RANGE		${1}	${NUMBER_OF_POSTS+1}
		${expected_post} = 			Fetch A Post From Database Matching		id		${id}
		# post will be added "comments" field having a list of comments
		Add Comments To Post		${expected_post}
		Append To List		${expected_posts}		${expected_post}
	END

	# at this moment, expected_posts contain posts, where each post has comments item having a list of comments
	# (2) test call
	${observed_posts} = 		Get All Posts With Their Comments Via Embed
	# if you want to compare the JSON formatted expected_posts and observed_posts
	# https://jsonformatter.org/json-parser
	Should Be Equal				${expected_posts}		${observed_posts}

Fetching A Post With Its Comments Via Embed
	[Documentation]			Referring to the API documentation:
	...						GET /posts/1?_embed=comments
	...						For a given post id (e.g. 1) the above API call returns the post together with its comments.
	...						(1) This test case fetches the expected_post with id from database along with its comments
	...						(2) It makes the API call returning observed_post
	...						Then this test case compare the observed_post with the expected_post
	[Tags]	read-tested		embed
	FOR  ${id}		IN RANGE		${1}	${NUMBER_OF_POSTS}
		# (1)
		${expected_post} = 			Fetch A Post From Database Matching		id		${id}
		# post will be added "comments" field having a list of comments
		Add Comments To Post		${expected_post}
		# (2) test call
		${observed_post} = 			Get A Post With Its Comments	${id}
		Should Be Equal				${expected_post}		${observed_post}
	END
