# Installation Instructions For Ubuntu

1. Install node v16.3.0 on your machine:
   https://github.com/nodesource/distributions/blob/master/README.md

2. Install json-server via npm:
   https://github.com/typicode/json-server#getting-started
   -  npm install -g json-server

3. Open Terminal 1: Clone the repo:
   -  git clone	https://github.com/TeddyTeddy/robot-fw-rest-instance-library-tests-v2.git

4. Terminal 1: At to the root of the cloned repo, execute:
   -  python -m venv .venv/
   -  source .venv/bin/activate
   -  pip install -r requirements.txt

5. Open a new Terminal 2, go to the root of the cloned repo and execute:
   -  json-server --watch db.json

At this point, you should have a JSON REST API server running locally on your machine
with the following output:

(base) ~/Python/Robot/robot-fw-rest-instance-library-tests-v2$ json-server --watch db.json

  \{^_^}/ hi!

  Loading db.json      <<  This file is at the root of the cloned repo
  Done

  Resources
  http://localhost:3000/posts
  http://localhost:3000/comments
  http://localhost:3000/albums
  http://localhost:3000/photos
  http://localhost:3000/users
  http://localhost:3000/todos

  Home
  http://localhost:3000


# Running The Test Cases
Referring to (4) in Terminal 1, execute:  ./run
