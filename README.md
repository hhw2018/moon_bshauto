# moon_bshauto

## Introduction
moon_bshauto is an automation framework implemented using bash script, which can
be used for both tests and tools automation. It supplys many libraries developed
for general system administration. And its capabilities can be extended by 
user-defined libraries, which will be used for users' business application.

A simplified version of a CI(continuous integration) system is supported. It 
assumes you're running against a git repository. 

## CI 
ci_observer.sh will check if there is any commit for each project defined in 
MOON_BSHAUTO_CI_PROJECTS by the end of everday; ci_dispatcher.sh will try to 
pick up idle runners from hosts defined in MOON_BSHAUTO_CI_RUNNER, and notify
the runners to kick off testing, runners will employ ci_runner.sh to run the 
specific test cases defined in {project_name}_{test_type} against the project.

{project_name}_{test_type} defined in ci.cfg holds the specific test cases to
be run against project "project_name", in which test_type is one of the 
following: functional or stress or longevity or performance.
```conf/framework/ci.cfg
  export MOON_BSHAUTO_CI_RUNNER="localhost 192.168.230.132"
  export moon_bshauto_functional="-d dir1 -d dir2"
  export moon_bshauto_stress="-d dir1 dir_2_tc2"
  export project2_functional="-d dir1"
  export project3_functional="-d dir1"
  export project4_functional="-d dir1"
  export MOON_BSHAUTO_CI_PROJECTS="moon_bshauto project2"
```
MOON_BSHAUTO_CI_PROJECTS holds a subset of git projects, it defines what 
projects will be monitored by CI.

## Directories and files
### bin
Script here can be executed separatly on the local host. Generally it is in a 
one-to-one relationship with another bshlib file defined in lib/framework, e.g.
net.sh and net.bshlib, net.sh calls the functions defined in net.bshlib to 
implement networking operations. Of course we can write any scripts implementing
any kinds of functions. 

### lib
#### lib/framework
Framework libraries can be used for framework as well as general system 
administration. e.g. net.bshlib is created for implementing networking related
operations while remote.bshlib is for executing commands on a remote node.
 
#### lib/user
User libraries are used for users' business purpose(tests or tools), they can 
call functions defined in framework libraries and always they are used only for
test cases and user tools. 

### conf
#### conf/framework
Environment variables are defined here which are used for framework.

#### conf/user
Environment variables are defined here which are used for users' business 
purpose, please be noted that we can re-defined framework environment 
variables here.

### tests
#### tests/project_name
You can put all your projects' test cases into tests directory,differentiated by
project_name, project_name can be specified in two ways:
1. With CI supported.
  project_name must be your git project name. MOON_BSHAUTO_CI_PROJECTS in ci.cfg
  holds all project names monitored by CI. 

  Here I put moon_bshauto into tests, which holds functional test cases against
  moon_bshauto project..

2. Without CI supported.
  project_name can be anything, put your functional, longevity, stress and
  performance test cases into tests/project_name directory, execute driver.sh to
  perform the testing directly.
```
    # Run all test cases in tests/abc/functional directory.
    driver.sh -f abc

    # Run test cases in dir1 and dir2 in tests/abc/stress directory.
    driver.sh -s abc -d dir1 -d dir2
```

##### tests/project_name/functional
functional directory holds functional test cases.

##### tests/project_name/longevity
longevity directory holds longevity test cases.

##### tests/project_name/stress
stress directory holds stress test cases.

##### tests/project_name/performance
performance directory holds performance test cases.

### tools
User-defined tools are created here, which are implemented for business purpose.
 
### ut
Put all ut scripts here.

### src
Often, we need to implement some functions with c programs, put the source code
into src directory, and install the binary files into bin.
```
  # cd src
  # make clean
  # make all
  # make install
``` 

## Examples
### Test Case Example
Please be noted that this is a sample for writing test cases. Please follow the
way to write your own:

* Test case directory 

  tests/moon_bshauto/functional/remote 

  So remote is created for functional testing against moon_bshauto project.
* config

  The config file defines all envrionment variables used for the test cases.
```
    export MOON_BSHAUTO_EXP_USER=root
    export MOON_BSHAUTO_EXP_USER_PASSWD=changeme
    export TEST_FILE=/tmp/test_file.$$
    export REMOTE=localhost
    export SIZE=10
  
```
* remote.bshlib

  The library file defines all functions used for the test cases.
```
    function cleanup {
        log_msg "cleanup: called before tc exits."
    }
    
    function cp_file_to_remote {
        # log_must means its following command must return a correct result, i.e. $? = 0.
        # the testing will abort if command fails.
        # Please refer to the log_ functions in log.bshlib file.
        log_must rcml scp -rp $TEST_FILE $MOON_BSHAUTO_EXP_USER@$REMOTE:${TEST_FILE}.dup
    }
    
    function chk_remote_file_exist {
        log_must rcml_host $REMOTE ls ${TEST_FILE}.dup
    }
    
    function chk_remote_file_size {
        local size=0
        size=$(rcml_host $REMOTE stat -c %s ${TEST_FILE}.dup)
        (( size = size / 1024 / 1024))
        log_must assert $size -eq $SIZE
    }
```
* setup

  The setup file will prepare the testing environment for the test cases.
```
    log_assert "Create a 10m file."
    log_must dd if=/dev/urandom of=$TEST_FILE bs=1M count=$SIZE
    log_pass "Created a 10m file."
```
* remote_tc_1, remote_tc_2, remote_tc_3

  Test cases hold the testing steps as well as the expected results.
```
    # Register functions defined in local lib file; driver.sh has already
    # register all framework lib functions; Also, we can register lib/user
    # functions here.
    . $MOON_BSHAUTO_TC_DIR/remote.bshlib
    
    # Register cleanup function, which can be called before tc exits.
    log_onexit cleanup 
    
    # Explicitly describe what the tc will verify.
    log_assert "Copy a local file to the remote."

    # The testing steps and expected results are defined in this function.
    cp_file_to_remote 

    # Explicitly give the PASSED result in log. Also, we have another log_fail
    # function to give the FAILED result.
    log_pass "Copied a local file to the remote sucessfully."
```
* cleanup

  The cleanup file will clean the testing environment after all test cases.
```
    log_assert "Remove the file created."
    log_must rm -rf $TEST_FILE
    log_pass "Removed the test file."
```
  **Please never rename the config/setup/cleanup files.**
  **Please always use suffix .bshlib for lib files.**

  Log snippet 
```
  # ./driver.sh -f moon_bshauto remote_tc_1
  # cd ../log/tests/moon_bshauto/functional/2018-04-09-11\:34\:29.8901/
  # more log.8901
  2018-04-09-11:34:29 TEST PATH BEGIN: /root/moon_bshauto/tests/moon_bshauto/functional/remote
  2018-04-09-11:34:29 VERIFY: Create a 10m file.
  2018-04-09-11:34:29 ACTION: dd if=/dev/urandom of=/tmp/test_file.8901 bs=1M count=10 (ret=0)
  2018-04-09-11:34:29 OUTPUT: 10+0 records in
  10+0 records out
  10485760 bytes (10 MB, 10 MiB) copied, 0.016631 s, 630 MB/s
  2018-04-09-11:34:29 PASSED: Created a 10m file.
  2018-04-09-11:34:29 TEST CASE: /root/moon_bshauto/tests/moon_bshauto/functional/remote/remote_tc_1
  2018-04-09-11:34:29 VERIFY: Copy a local file to the remote.
  2018-04-09-11:34:30 ACTION: rcml scp -rp /tmp/test_file.8901 root@localhost:/tmp/test_file.8901.dup (ret=0)
  2018-04-09-11:34:30 OUTPUT: test_file.8901                                                                                                0%
    0     0.0KB/s   --:-- ETAtest_file.8901                                                                                              100%
    10MB  10.0MB/s   00:00
  2018-04-09-11:34:30 PASSED: Copied a local file to the remote sucessfully.
  2018-04-09-11:34:30 ONEXIT: Call function 'cleanup'
  2018-04-09-11:34:30 cleanup: called before tc exits.
  2018-04-09-11:34:30 VERIFY: Remove the file created.
  2018-04-09-11:34:30 ACTION: rm -rf /tmp/test_file.8901 (ret=0)
  2018-04-09-11:34:30 OUTPUT:
  2018-04-09-11:34:30 PASSED: Removed the test file.
  2018-04-09-11:34:30 TEST PATH END: /root/moon_bshauto/tests/moon_bshauto/functional/remote
```
### Tools Example
For the tools executed directly, please refer to tools/deploy.sh.
For the tools executed by driver.sh, please refer to tools/test_remote_bshlib.sh.

## Usage
1. On a local linux machine, clone moon_bshauto.
2. Enter the src directory and make binary tools.
```
  # cd src
  # make clean
  # make all
  # make install
``` 
3. Deploy moon_bshauto to the remote nodes.
```
  # moon_bshauto/tools/deploy.sh
  Usage: deploy.sh -f host_file|-h host_list [-d path]
  host_file: file with host names or ips separated by new-line char.
  host_list: list of host names or ips separated by space.
  path: work home where the framework will be installed(/var/log by default).
  
  # moon_bshauto/tools/deploy.sh -h 192.168.78.78
```
4. Run test cases without CI supported.
```
  # moon_bshauto/bin/driver.sh
  Usage: driver.sh -f|-s|-p|-l proj [-d dir1 [-d dir2] ...] [tc [tc] ...]
    -f: Perform functional testing under tests/functional.
    -s: Perform stress testing under tests/stress.
    -p: Perform performance testing under tests/performance.
    -l: Perform longevity testing under tests/longevity.
  proj: The project name.
    -d: Test case directory name.
    tc: Test case name, which is global unique.
  
  # moon_bshauto/bin/driver.sh -f moon_bshauto -d remote
```
5. Run test cases with CI supported.

5.1 Configure conf/framework/ci.cfg. Please refer to the comments in ci.cfg.

5.2 Add ci_observer.sh into crontab, let it run by the end of every day.

6. Run tools in two ways:
* Execute the tool directly.

  Register the necessary libraries and configuration files by the tool itself.
```  
  # moon_bshauto/tools/deploy.sh -h 192.168.78.78
```
* Execute the tool by driver.sh.

  driver.sh has registered all the framework libraries and configuration files,

  users can focus on their business purpose.
```
  # moon_bshauto/bin/driver.sh -t "tool arglist".

```
