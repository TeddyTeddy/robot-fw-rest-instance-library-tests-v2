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

Fetch Comments from Database
	[Documentation]		Returns the comments from the database for the given post with post_id
	...					Sorts the comments by the field in the given order
	[Arguments]			${post_id}		${field}		${order}
	${comments} = 		Fetch From Database 	comments
	${comments} =		Filter Resource List By 		${comments}		postId		${post_id}
	${comments} =		Sort Resource List		${comments}	 	${field}	${order}
	[Return]	${comments}

Fetch Ordered Comments From Database For A Given PostId Ordered By Given Fields
	[Documentation]		Returns the comments with a given post_id
	[Arguments]			${post_id}		${field_1}		${order_1}	  	${field_2}		${order_2}
	${comments} = 		Fetch From Database 	comments
	${comments} =		Filter Resource List By 		${comments}		postId		${post_id}
	${comments} =		Sort Resource List		${comments}	 	${field_1}	${order_1}
	${comments} =		Sort Resource List		${comments}	 	${field_2}	${order_2}
	[Return]			${comments}