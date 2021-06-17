from robot.api.deco import keyword
from robot.api import logger
from operator import itemgetter


@keyword
def get_page_set(total, limit):
	"""
		Given total (number of posts in the db) and limit (of number of posts in a page)
		it calculates the page indexes (i.e. page index 1, 2, 3, ... last_page_index), where last_page_index is the
		index of the last page.
	"""
	assert limit > 0
	page = 1
	pages = [page]
	total -= limit
	while total > 0:
		page += 1
		pages.append(page)
		total -= limit
	logger.info(pages)
	return pages

@keyword
def get_empty_pages(pages_with_resources):
	""" Given the list pages_with_resources (e.g. [1,2,3]), which contains the last page index (e.g. 3),
		this function returns a list of pages, which should contain no resources (e.g. 4, 5, 6, 7, 8, ...)
	"""
	last_page_index = pages_with_resources[len(pages_with_resources)-1]
	empty_pages = list(range(last_page_index+1, last_page_index+6))
	empty_pages.append(last_page_index+11)
	empty_pages.append(last_page_index+21)
	empty_pages.append(last_page_index+31)
	empty_pages.append(last_page_index+41)
	empty_pages.append(last_page_index+51)
	empty_pages.append(last_page_index+101)
	empty_pages.append(last_page_index+201)
	return empty_pages


@keyword
def sort_posts_by_id(posts, order):
	# https://stackoverflow.com/questions/72899/how-do-i-sort-a-list-of-dictionaries-by-a-value-of-the-dictionary
	if order == 'asc':
		sorted_posts = sorted(posts, key=itemgetter('id'), reverse=False)	# reverse=True for ascending order
	elif order == 'desc':
		sorted_posts = sorted(posts, key=itemgetter('id'), reverse=True)	# reverse=True for descending order
	else:
		assert False
	return sorted_posts
