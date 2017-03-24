var argv = require('minimist')(process.argv.slice(2)),
	neo4j = require('neo4j-driver').v1,
	async = require('async'),
	fs = require('fs'),
	config = {
		url: argv.url? argv.url: 'bolt://localhost:7687',
		user: argv.user? argv.user: 'neo4j',
		pass: argv.pass? argv.pass: 'neo4j',
		filename: argv._[0]? argv._[0]: 'cypher.cql'   
	},
	driver = new neo4j.driver(config.url, neo4j.auth.basic(config.user, config.pass)),
	cqls = fs.readFileSync(`./${config.filename}`, 'utf-8'),
	fns = cqls.split(';')
			.map((cql) => (
				(callback)=>{
					var session = driver.session();
					console.log(cql);
					session.run(cql)
						.then(function() {
							session.close();
							callback(null, cql);
						}).catch(function(err) {
							session.close();
							callback(err, cql)
						});
				})
			)

async.series(fns, function(err, result) {
	if(err) {
		console.log(err);
	} else {
		console.log("query executeing is done!");
		console.log(result);
	}
});


