from robot.api.deco import keyword
from robot.api import logger
import jsonpickle


@keyword
def	set_item(key, value, json_resource):
	resource = jsonpickle.decode(json_resource)
	resource[key] = value
	return jsonpickle.encode(resource)

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
