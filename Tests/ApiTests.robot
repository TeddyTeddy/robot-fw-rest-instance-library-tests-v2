*** Settings ***
Documentation		All test cases are atomic: after the test execution, they must leave the
...					system in the same state before the execution. To accomplish atomic tests,
...					the test teardown method Restore Database gets called. This restores the
...					backend server's database to initial state before the test execution.
Resource			${EXECDIR}${/}Resources${/}Common${/}Common.resource
Resource			${EXECDIR}${/}Resources${/}Posts.resource

Test Teardown		Restore Database


*** Variable ***
${NEW_POST_ID}				Value to be set dynamically
${JSON_POST}				{"userId":1,"title":"First blog post","body":"Body content"}
${MODIFIED_JSON_POST}
${NEW_USER_ID}				${2}
${NEW_TITLE}				Modified Title
${NEW_BODY}					Modified Body


*** Test Case ***
Creating Post
	[Documentation]			Creates a new post with JSON_POST (1) and retrives its id and the new post itself (2)
	...						A) Checks that (2) contains all the key/value pairs in (1).
	...						B) With the id, it reads the post once again (3) and compares
	...						that with (2). They must match exactly.
	[Tags]		create		read
	# test call: create a new post
	${new_post_id}		${new_post} = 	Create Post		${JSON_POST}

	# A) verify that ${new_post} content contains the items from ${JSON_POST}
	Is Superset			${new_post}		${JSON_POST}

	# B) verify that what is created can indeed be retrived too
	${post_read} = 		Get Post With Id	${new_post_id}
	Should Be Equal		${new_post}		${post_read}


Updating Post UserId
	[Documentation]			Creates a post with JSON_POST (1) and updates its "userId" locally
	...						by calling Update Post UserId, which
	...						then makes a PUT request updating the resource in the server.
	...						Checks that the post resource in the server got updated
	...						by calling Verify Post Updated
	[Tags]		create	read	update
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
	[Tags]		create	read	update
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
	[Tags]		create	read	update
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}

	# test call: update the post with post_id
	Update Post Body				${post_id}		${expected_post}		${NEW_BODY}
	# expected_post got updated with "body"=${NEW_BODY}
	Verify Post Updated		${post_id}		${expected_post}

Update Post UserId & Title
	[Documentation]			TODO: Add documentation
	[Tags]		create	read	update
	#	prepare the post to be updated
	${post_id}		${expected_post} = 	Create Post		${JSON_POST}

	# update the post locally

