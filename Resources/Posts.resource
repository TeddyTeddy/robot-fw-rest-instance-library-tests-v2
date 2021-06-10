*** Settings ***
Documentation		Implements CRUD operations for /posts endpoint
Library				REST		${API_BASE_URL}
Library				Collections
#Library             Utilities

*** Keywords ***
Get Post With Id
	[Documentation]		Given post_id, it makes a GET request and returns the response body as the post
	[Arguments]		${post_id}
	GET			/posts/${post_id}
	${post} =	Output		response body
	[Return]	${post}

Get Posts With Filter
	[Documentation]		Given filter, it makes a GET request and returns the response body as the post
	[Arguments]		${filter}
	GET			/posts${filter}
	${post_list} =	Output		response body
	[Return]	${post_list}

Create Post
	[Documentation]		Given the json_post (i.e. a JSON representation of a post), it makes a POST
	...					request. The response body to the POST request is the new post and there is an id
	...					item in the post. This keyword returns the id and the new post to the caller
	[Arguments]		${json_post}
	POST	/posts	${json_post}
	${new_post_id} = 	Output		response body id
	${new_post} =		Output		response body
	[Return]	${new_post_id}		${new_post}

Update Post UserId
	[Documentation]			post is a dictionary
	[Arguments]				${post_id}		${post}		${new_user_id}
	Set To Dictionary		${post}		userId=${new_user_id}
	PUT		/posts/${post_id}		${post}

Update Post Title
	[Documentation]			post is a dictionary
	[Arguments]				${post_id}		${post}		${new_title}
	Set To Dictionary		${post}		title=${new_title}
	PUT		/posts/${post_id}		${post}

Update Post Body
	[Documentation]			post is a dictionary
	[Arguments]				${post_id}		${post}		${new_body}
	Set To Dictionary		${post}		body=${new_body}
	PUT		/posts/${post_id}		${post}

Verify Post Updated
	[Documentation]			expected_post is a dictionary
	[Arguments]				${post_id}		${expected_post}
	${observed_post} = 		Get Post With Id		${post_id}
	Should Be Equal			${expected_post}		${observed_post}

Update Post
	[Documentation]			post is a dictionary
	[Arguments]				${post_id}		${post}
	PUT		/posts/${post_id}		${post}

Delete Post With Id
	[Documentation]		Given post_id, it makes a DELETE request
	[Arguments]		${post_id}
	DELETE			/posts/${post_id}

Read All Posts
	[Documentation]		Returns all post resources
	GET		/posts
	${posts} =	Output		response body
	[Return]	${posts}