# moon_bshauto

## Introduction
moon_bshauto is an automation framework implemented using bash script, which can
be used for both tests and tools automation. It will supply many libraries 
developed for general system administration use. And its capabilities can be 
extended by user-defined libraries, used for users' business application.

## Directory
### bin
Script here can be executed separatly on the local host. Generally it is in a 
one-to-one relationship with another bshlib file defined in lib/framework, e.g.
net.sh and net.bshlib, net.sh calls the functions defined in net.bshlib to 
implement networking operations. Of course we can write any scripts implementing
any kinds of functions. 

### lib
#### framework
Framework libraries can be used for framework as well as general system 
administration. e.g. net.bshlib is created for implementing networking related
operations while remote.bshlib is for executing commands on a remote node.
 
#### user
User libraries are used for users' business purpose(tests or tools), they can 
call functions defined in framework libraries and always they are used only for
test cases and user tools. 

### conf
#### framework
Environment variables are defined here which are used for framework.

#### user
Environment variables are defined here which are used for users' business 
purpose, please be noted that we can re-defined framework environment 
variables here.

### tests
#### functional
It includes functional test cases.

#### longevity
It includes longevity test cases.

#### stress
It includes stress test cases.

#### performance
It includes performance test cases.

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
way to write your own test cases:

* Test case directory 

  ut_tests

  Put ut_tests into one of the directories: functional/stress/longevity/performance.
* config

  The config file defines all envrionment variables used for the test cases.
```
    export MOON_BSHAUTO_EXP_USER=root
    export MOON_BSHAUTO_EXP_USER_PASSWD=changeme
    export TEST_FILE=/tmp/test_file.$$
    export REMOTE=localhost
    export SIZE=10
  
```
* dir_1.bshlib

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
* dir_1_tc1, dir_1_tc2, dir_1_tc3

  Test cases.
```
    # Register functions defined in local lib file; driver.sh has already
    # register all framework lib functions; Also, we can register user lib
    # functions here.
    . $MOON_BSHAUTO_TC_DIR/dir_1.bshlib
    
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

  Log snippet 
```
    2018-04-04-22:16:48 TEST CASE: /root/moon_bshauto/tests/functional/ut_tests/dir_1_tc1
    2018-04-04-22:16:48 VERIFY: Copy a local file to the remote.
    2018-04-04-22:16:48 ACTION: rcml scp -rp /tmp/test_file.10480 root@localhost:/tmp/test_file.10480.dup (ret=0)
    2018-04-04-22:16:48 OUTPUT: test_file.10480      0% 0     0.0KB/s   --:-- ETAtest_file.10480                                                                                             100% 10MB  10.0MB/s   00:00
    2018-04-04-22:16:48 PASSED: Copied a local file to the remote sucessfully.
    2018-04-04-22:16:48 ONEXIT: Call function 'cleanup'
    2018-04-04-22:16:48 cleanup: called before tc exits.
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
4. Run test cases
```
  # moon_bshauto/bin/driver.sh
  Usage: driver.sh -f|-s|-p|-l [-d dir1 [-d dir2] ...] [tc [tc] ...]
    -f: Perform functional testing under tests/functional.
    -s: Perform stress testing under tests/stress.
    -p: Perform performance testing under tests/performance.
    -l: Perform longevity testing under tests/longevity.
    -d: Test case directory name.
    tc: Test case name, which is global unique.
  
  # moon_bshauto/bin/driver.sh -f -d ut_test 
```
5. Two ways to run tools:
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
