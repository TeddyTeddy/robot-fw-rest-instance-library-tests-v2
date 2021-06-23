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
	... 				from the database starting with page_start_index (inclusive, starting from zero)
	...					and ending with page_end_index (exclusive).
	...					Otherwise returns all the posts in the database
	[Arguments]		${start_index}=${EMPTY}		${end_index}=${EMPTY}
	${all_posts} = 		Fetch From Database 	posts
	${is_range_provided} = 		Evaluate	$start_index!='' and $end_index!=''
	IF	${is_range_provided}
		${ranged_posts} =		Evaluate		$all_posts[$start_index:$end_index]
		Free Memory		${all_posts}
		Return From Keyword		${ranged_posts}
	END
	[Return]	${all_posts}

Fetch Posts From Database With GTE and LTE For A Field
	[Documentation]		Given field_name (e.g. id) returns all the posts
	...					whose id stays in the range [gte, lte] for that field_name
	[Arguments]			${field_name}		${gte}		${lte}
	${posts} = 		Fetch From Database 	posts
	FOR		${post}		IN 		@{posts}
		${is_match} = 	Evaluate	$post[$field_name] >= $gte and $post[$field_name] <= $lte
		IF    not ${is_match}
			${index} = 		Get Index From List		${posts}		${post}
			Remove From List	${posts}	${index}
		END
	END
	[Return]	${posts}

Fetch Comments from Database
	[Documentation]		Returns the comments from the database for the given post with post_id
	...					Sorts the comments by the field in the given order
	[Arguments]			${post_id}		${field}		${order}
	${comments} = 		Fetch From Database 	comments
	# comments is modified in place
	Filter In Resource List By 		${comments}		postId		${post_id}
	${sorted_comments} =		Sort Resource List		${comments}	 	${field}	${order}
	Free Memory		${comments}
	[Return]	${sorted_comments}

Fetch Ordered Comments From Database For A Given PostId Ordered By Given Fields
	[Documentation]		Returns the comments with a given post_id
	[Arguments]			${post_id}		${field_1}		${order_1}	  	${field_2}		${order_2}
	${comments} = 		Fetch From Database 	comments
	# comments is modified in place
	Filter In Resource List By 		${comments}		postId		${post_id}
	${phase_1_sorted_comments} =		Sort Resource List		${comments}	 	${field_1}	${order_1}
	Free Memory		${comments}
	${final_sorted_comments} =		Sort Resource List		${phase_1_sorted_comments}	 	${field_2}	${order_2}
	Free Memory		${phase_1_sorted_comments}
	[Return]			${final_sorted_comments}

Fetch A Post From Database Matching
	[Documentation]		given field_name (e.g. id) and value (e.g. 5), this keyword returns the post whose field_name
	...					matches value
	[Arguments]			${field_name}		${field_value}
	${posts} = 			Fetch From Database 	posts
	FOR		${post}		IN 		@{posts}
		${is_match} = 	Evaluate	$post[$field_name] == $field_value
		IF  ${is_match}
			Free Memory		${posts}
			Return From Keyword		${post}
		END
	END
	[Return]	${EMPTY}

Add Comments To Post
	[Documentation]		Given the post, it will add "comments" field having a list of all the comments for that post.
	...					A comment belongs to a post if its postId matches the posts id
	[Arguments]			${post}
	${all_comments} = 		Fetch From Database 	comments
	${posts_comments} =		Create List
	FOR		${comment}		IN 		@{all_comments}
		${is_match} =		Evaluate	$comment['postId'] == $post['id']
		IF		${is_match}
			Append To List		${posts_comments}		${comment}
		END
	END
	Set To Dictionary		${post}		comments=${posts_comments}
	Free Memory		${all_comments}

