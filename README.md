# Installation Instructions For Ubuntu

1. Install node v16.3.0 on your machine:
   https://github.com/nodesource/distributions/blob/master/README.md

2. Install json-server globally via npm:
   https://github.com/typicode/json-server#getting-started
   -  npm install -g json-server

3. Open Terminal 1: Clone the repo:
   -  git clone	https://github.com/TeddyTeddy/robot-fw-rest-instance-library-tests-v2.git

4. Terminal 1: At to the root of the cloned repo, execute:
   -  python -m venv .venv/
   -  source .venv/bin/activate
   -  pip install -r requirements.txt
   Keep terminal 1 open.

5. Open a new Terminal 2, go to the root of the cloned repo and execute:  ./install-server-with-authentication

Now you are ready to run the server (in Terminal 2). You have 2 options;
   - running the server with authentication
   - running the server without authentication

# Running the server without authentication
6. In terminal 2, at the project root; ./run_server_with_authentication

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
# Running the server with authentication
6. In terminal 2, at the project root; ./run_server_without_authentication

 JSON Server is running with authentication enabled

# Running The Test Cases
In Terminal 1, execute:  ./run_all_tests_in_one_batch  (RAM memory heavy)
In Terminal 1, execute:  ./run_all_tests_in_batches    (RAM memory friendly)

The difference between the two is that the first one runs the all the test suites in one go.
Since test cases in the suites require a lot of memory, the amount of memory allocated to robot
execution increases constantly with this approach. The second one runs one test case at a time
and saves its result to an XML file and finishes the test execution. Since the execution
ends at the end of each test case, the memory is freed too. This way we do not require an increasing
amount of memory allocation to robot execution as the tests run.

