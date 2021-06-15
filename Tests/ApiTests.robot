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

Test Teardown		Restore Database


*** Variable ***
${NEW_POST_ID}				Value to be set dynamically
${JSON_POST}				{"userId":1,"title":"First blog post","body":"Body content"}
${MODIFIED_JSON_POST}
${NEW_USER_ID}				${2}
${NEW_TITLE}				Modified Title
${NEW_BODY}					Modified Body
${TAGS}						tag1 tag2 tag3
&{EXPECTED_POST_WITH_ID_5}			userId=${1}
...    								id=${5}
...    								title=nesciunt quas odio
...    								body=repudiandae veniam quaerat sunt sed\nalias aut fugiat sit autem sed est\nvoluptatem omnis possimus esse voluptatibus quis\nest aut tenetur dolor neque


*** Keywords ***
Getting Posts With Pagination
	[Documentation]			limit stands for number of posts in a given page
	...						total stands for number of posts in the database
	...						pages is a set containing page numbers based on a given limit and total
	...						A page is a list of posts returned by GET /posts?_page=${p}&_limit=${limit}
	[Arguments]		${limit}

	${total} = 		Get Number of Posts			# total is 100
	${pages} = 		Get Page Set	${total}	${limit}

	FOR  ${p}	IN   @{pages}
		${page_start_index} =		Evaluate		$limit*($p-1)
		${page_end_index} =			Evaluate		$limit*$p
		${expected_posts} =			Fetch Posts From Database	${page_start_index}		${page_end_index}
		${expected_link_header} =	Calculate Link Header		${pages}	${p}	${limit}
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
	${observed_post} = 		Get Post With Id	${5}
	# verify
	Should Be Equal		${observed_post}		${EXPECTED_POST_WITH_ID_5}

Reading Post By Filtering Id
	[Documentation]			Reads posts by providing a filter containing a id value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?id=${EXPECTED_POST_WITH_ID_5}[id]
	# test call
	${post_list} = 			Get Posts With Filter	${filter}
	# verify
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST_WITH_ID_5}		${post_list}[0]

Reading Post By Filtering Title
	[Documentation]			Reads posts by providing a filter containing a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?title=${EXPECTED_POST_WITH_ID_5}[title]
	# test call
	${post_list} = 			Get Posts With Filter	${filter}
	# verify
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST_WITH_ID_5}		${post_list}[0]

Reading Post By Filtering Id & Title
	[Documentation]			Reads posts by providing a filter containing an id value and a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?id=${EXPECTED_POST_WITH_ID_5}[id]&title=${EXPECTED_POST_WITH_ID_5}[title]
	# test call
	${post_list} = 			Get Posts With Filter	${filter}
	# verify
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST_WITH_ID_5}		${post_list}[0]

Reading Post By Filtering UserId and Title
	[Documentation]			Reads posts by providing a filter containing a userId value and a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?userId=${EXPECTED_POST_WITH_ID_5}[userId]&title=${EXPECTED_POST_WITH_ID_5}[title]
	${post_list} = 			Get Posts With Filter	${filter}
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST_WITH_ID_5}		${post_list}[0]

Reading Post By Filtering UserId, Id and Title
	[Documentation]			Reads posts by providing a filter containing a userId value, id value and a title value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?userId=${EXPECTED_POST_WITH_ID_5}[userId]&id=${EXPECTED_POST_WITH_ID_5}[id]&title=${EXPECTED_POST_WITH_ID_5}[title]
	${post_list} = 			Get Posts With Filter	${filter}
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST_WITH_ID_5}		${post_list}[0]

Reading Post By Filtering UserId And Id
	[Documentation]			Reads posts by providing a filter containing a userId value and an id value
	...						Expects that the returned post list contains only one post
	...						Expects that the post matches with the expected post
	[Tags]		read-tested
	${filter} = 			Set Variable		?userId=${EXPECTED_POST_WITH_ID_5}[userId]&id=${EXPECTED_POST_WITH_ID_5}[id]
	${post_list} = 			Get Posts With Filter	${filter}
	${observed_length} = 	Get Length		${post_list}
	Should Be Equal		${1}	${observed_length}
	Should Be Equal		${EXPECTED_POST_WITH_ID_5}		${post_list}[0]

Updating Post UserId
	[Documentation]			Creates a post with JSON_POST (1) and updates its "userId" locally
	...						by calling Update Post UserId, which
	...						then makes a PUT request updating the resource in the server.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update-tested
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}

	# test call: update the post with post_id
	Update Post UserId			${post_id}		${expected_post}		${NEW_USER_ID}
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

	# test call: update the post with post_id
	Update Post Title				${post_id}		${expected_post}		${NEW_TITLE}
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

	# test call: update the post with post_id
	# expected_post gets its body updated with NEW_BODY
	Update Post Body				${post_id}		${expected_post}		${NEW_BODY}
	# expected_post got updated with "body"=${NEW_BODY}
	Verify Post Updated		${post_id}		${expected_post}

Update Post UserId & Title
	[Documentation]			Creates a post with JSON_POST (1) and updates its "title" and "userId" items locally
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
	Log		Expected post got locally modified: ${expected_post}
	# test call: update the post in the server
	Update Post		${post_id}		${expected_post}
	Verify Post Updated		${post_id}		${expected_post}

Update Post Title & Body
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

Update Post UserId & Body
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

Update All Fields Except Id In Post
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
	${expected_error} = 	Set Variable	{'userId': 2, 'title': 'Modified Title', 'body': 'Modified Body', 'id': 102} != {'userId': 2, 'title': 'Modified Title', 'body': 'Modified Body', 'id': 101}
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
	Run Keyword And Expect Error		{} != {'id': 101}	Verify Post Updated		${post_id}		${expected_post}
	# update expected_post locally
	Set To Dictionary			${expected_post}		id=${post_id}
	# verify that post resource has only id field with post_id value
	Verify Post Updated		${post_id}		${expected_post}

Remove All Fields Except Id In Post
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

Remove Title From Post
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

Remove Body From Post
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

Remove UserId From Post
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

Remove Title And Body In Post
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

Remove Title And UserId In Post
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

Remove Body And UserId In Post
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

Pagination Where Limit Exceeds Total
	[Documentation]		limit stands for the number of posts per page (i.e. 200 for the purpose)
	...					total stands for the number of posts in the database (i.e. 100 currently)
	...					When limit exceeds total, a single page must contain all the posts in the database
	[Tags]	read-tested   pagination	run
	[Template]			Getting Posts With Pagination
	${200}

Pagination Where Limit Equals To Total
	[Documentation]		limit stands for the number of posts per page (i.e. 100 for the purpose)
	...					total stands for the number of posts in the database (i.e. 100 currently)
	...					When limit equals to total, a single page must contain all the posts in the database
	[Tags]	read-tested   pagination	run
	[Template]			Getting Posts With Pagination
	${100}

Pagination Where Limit Is Less Than Total
	[Documentation]		limit stands for the number of posts per page (i.e. 8, 20 and 50 for the purpose)
	...					total stands for the number of posts in the database (i.e. 100 currently)
	...					When limit equals to total, a single page can only contain limit number of the posts
	[Tags]	read-tested   pagination	run
	[Template]			Getting Posts With Pagination
	${80}
	${50}
	${20}
	${8}