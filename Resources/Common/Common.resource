*** Settings ***
Documentation		add documentation here
Library				OperatingSystem
Library				Collections


*** Variable ***
${API_BASE_URL}				http://localhost:3000/


*** Keywords ***
Restore Database
	[Documentation]			By checking out the stored version of the db.json, we revert the effects of CRUD requests
	...						in the test cases. Note that JSONSERVER listens to the changes in db.json, it re-starts
	...						each time db.json is updated.
	Run			git checkout ${EXECDIR}${/}db.json
	Sleep		1s			# allow JSONSERVER to reboot itself after db.json file change

Is Superset
	[Documentation]		Expects resource_one as dictionary like, turns it into a Python dictionary
	...					Expects resource_two as a string representation of a dictionary,
	...					converts it into a Python dictionary
	...					If resource_one contains the subdictionary resource_two, then it passes
	...					otherwise it fails
	[Arguments]		${resource_one}			${resource_two}
	${resource_one} =	 Convert To Dictionary		${resource_one}
	${resource_two} =	 Evaluate		eval($resource_two)
	Dictionary Should Contain Sub Dictionary	${resource_one}		${resource_two}
