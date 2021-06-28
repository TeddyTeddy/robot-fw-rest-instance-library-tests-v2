*** Settings ***
Documentation		Implements CRUD operations for /posts endpoint
Library				REST		${API_BASE_URL}
Library				Collections
#Library             Utilities

*** Keywords ***

Create Request Headers
	[Documentation]		If user type is Authorized, return a JSON representation of a dictionary containing PRIVATE_API_KEY
	...					If user type is UnAuthorized, return a JSON representation of an empty dictionary
	...					Otherwise fail
	[Arguments]		${user_type}
	IF		'${user_type}'=='Authorized'
			${headers} =		Set Variable	{ "privateKey": "%{PRIVATE_API_KEY}" }
	ELSE IF	'${user_type}'=='UnAuthorized'
			${headers} =		Set Variable	{}
	ELSE
		Fail		Unknown user_type:${user_type}
	END
	[Return]	${headers}

Get Post With Id
	[Documentation]		Given post_id, it makes a GET request and returns the response body as the post
	[Arguments]		${post_id}		${user_type}=Authorized

	${headers} = 	Create Request Headers		${user_type}
	GET			/posts/${post_id}		headers=${headers}
	${post} =	Output		response body
	[Return]	${post}

Get Posts With Filter
	[Documentation]		Given filter, it makes a GET request and returns the response body as the posts
	[Arguments]		${filter}	${user_type}=Authorized

	${headers} = 	Create Request Headers		${user_type}
	GET			/posts${filter}		headers=${headers}
	${post_list} =	Output		response body
	[Return]	${post_list}

Get Posts With Pagination
	[Documentation]		Given pagination parameters page and limit, it makes a GET request and returns the response body as the posts
	[Arguments]		${page}			${limit}	${user_type}=Authorized

	${headers} = 	Create Request Headers		${user_type}
	IF		${limit}==${DEFAULT_PAGE_LIMIT}
		# Acc.to the API documentation, 10 items per page are returned by default
		# if we don't provide limit, which has value 10, API should assume that limit is 10
		GET			/posts?_page=${page}	headers=${headers}
	ELSE
		GET			/posts?_page=${page}&_limit=${limit}		headers=${headers}
	END
	${post_list} =		Output		response body
	${link_header} = 	Output		response headers Link
	[Return]	${post_list}	${link_header}

Create Post
	[Documentation]		Given the json_post (i.e. a JSON representation of a post), it makes a POST
	...					request. The response body to the POST request is the new post and there is an id
	...					item in the post. This keyword returns the id and the new post to the caller
	[Arguments]		${json_post}	${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	POST	/posts	${json_post}		headers=${headers}
	${new_post_id} = 	Output		response body id
	${new_post} =		Output		response body
	[Return]	${new_post_id}		${new_post}

Verify Post Updated
	[Documentation]			expected_post is a dictionary
	[Arguments]				${post_id}		${expected_post}
	${observed_post} = 		Get Post With Id		${post_id}
	Should Be Equal			${expected_post}		${observed_post}

Update Post
	[Documentation]			post is a dictionary
	[Arguments]				${post_id}		${post}		${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	PUT		/posts/${post_id}		${post}		headers=${headers}


Delete Post With Id
	[Documentation]		Given post_id, it makes a DELETE request
	[Arguments]		${post_id}		${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	DELETE			/posts/${post_id}		headers=${headers}

Read All Posts
	[Documentation]		Returns all post resources
	[Arguments]		${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET		/posts		headers=${headers}
	${posts} =	Output		response body
	[Return]	${posts}

Get Posts By Id In Ascending Order
	[Documentation]		Returns posts by id in ascending order
	[Arguments]		${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET		/posts?_sort=id&_order=asc		headers=${headers}
	${posts} =	Output		response body
	[Return]	${posts}

Get Posts By Id In Descending Order
	[Documentation]		Returns posts by id in descending order
	[Arguments]		${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET		/posts?_sort=id&_order=desc		headers=${headers}
	${posts} =	Output		response body
	[Return]	${posts}

Get Comments For A Specific Post
	[Documentation]		For a given post_id, it returns the comments with that post_id
	...					Sorts the results based on field_1 (and field_2) in a given orders order_1 (and order_2)
	[Arguments]		${post_id}		${field_1}		${order_1}		${field_2}=${EMPTY}		${order_2}=${EMPTY}		${user_type}=Authorized

	${headers} = 	Create Request Headers		${user_type}
	${is_field_2_provided} = 	Evaluate	$field_2!='' and $order_2!=''
	IF	${is_field_2_provided}
		GET		/posts/${post_id}/comments?_sort=${field_1},${field_2}&_order=${order_1},${order_2}		headers=${headers}
	ELSE
		GET		/posts/${post_id}/comments?_sort=${field_1}&_order=${order_1}		headers=${headers}
	END
	${comments} =	Output		response body
	[Return]	${comments}

Get Sliced Posts
	[Documentation]		start_index starts from 0 for slicing operation
	[Arguments]			${start_index}		${end_index}	${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET		/posts?_start=${start_index}&_end=${end_index}		headers=${headers}
	${posts} =	Output		response body
	[Return]	${posts}

Get Sliced Posts Using Limit
	[Documentation]		start_index starts from 0 for slicing operation
	[Arguments]			${start_index}		${limit}	${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET		/posts?_start=${start_index}&_limit=${limit}		headers=${headers}
	${posts} =	Output		response body
	[Return]	${posts}

Get Posts With GTE, LTE And NE Values For Field Name One and Like Values For Field Name Two
	[Documentation]		Keep in mind that we are making a GET request for a post resource.
	...					For a given field name_1 (e.g. id) then we use 3 operators:
	...					GTE (greater than or equal to) (e.g. 10)
	...					LTE (less than or equal to) (e.g. 20)
	...					NE (not equal to) (e.g. 15)
	...					For a given field name_2 (e.g. title) we use a Like value (e.g. lorem)
	...					So, given the example values, we would make:
	...					GET		/posts?id_gte=10&id_lte=20&id=15&title_like=lorem
	...					The response body of this call would be a list of posts matching the GTE, LTE, NE and
	...					Like criterias.
	[Arguments]			${field_name_1}		${gte}		${lte}		${ne}		${field_name_2}		${like}		${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET		/posts?${field_name_1}_gte=${gte}&${field_name_1}_lte=${lte}&${field_name_1}_ne=${ne}&${field_name_2}_like=${like}		headers=${headers}
	${posts} =	Output		response body
	[Return]	${posts}

Get A Post With Its Comments
	[Documentation]		Given a post id (e.g. 1), we make the following GET call:
	...					GET /posts/1?_embed=comments
	...					The response body of this call would be a post having "comments" item
	...					which is a list of comments.
	[Arguments]			${id}		${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET 				/posts/${id}?_embed=comments		headers=${headers}
	${post} =	Output		response body
	[Return]	${post}

Get All Posts With Their Comments Via Embed
	[Documentation]		This returns a list of all posts where each post contains its own embedded comment list
	[Arguments]			${user_type}=Authorized
	${headers} = 	Create Request Headers		${user_type}
	GET 				/posts/?_embed=comments		headers=${headers}
	${posts} =	Output		response body
	[Return]	${posts}