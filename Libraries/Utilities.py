from robot.api.deco import keyword
from robot.api import logger
import jsonpickle


@keyword
def	set_item(key, value, json_resource):
	resource = jsonpickle.decode(json_resource)
	resource[key] = value
	return jsonpickle.encode(resource)