const jsonServer = require('./node_modules/json-server');
const server = jsonServer.create();
const router = jsonServer.router('db.json', '--watch');
const middlewares = jsonServer.defaults();

server.use(middlewares);
server.use((req, res, next) => {
	function isAuthorized(req) {
		// console.log(req.get('privateKey'))
		if (req.get('privateKey')=='1234567') {
			return true
		}
		return false
	}
	if (isAuthorized(req)) { // add your authorization logic here
		next() // continue to JSON Server router
	} else {
		res.sendStatus(401)
	}
})
server.use(router);
server.listen(3000, () => {
  console.log('JSON Server is running with authentication enabled')
});