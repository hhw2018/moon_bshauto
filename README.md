# moon_bshauto

## Introduction
moon_bshauto is an automation framework implemented using bash script, which can be used
for both tests and tools automation. It will supply many libraries developed for general
system administration use. And its capabilities can be extended by user-defined libraries,
used for users' business application.

## Directory
### bin
Script here can be executed separatly on the local host. Generally it is in a one-to-one 
relationship with another bshlib file defined in lib/framework, e.g. net.sh and net.bshlib,
net.sh calls the functions defined in net.bshlib to implement networking operations. Of 
course we can write any scripts implementing any kinds of functions. 

### lib
#### framework
Framework libraries can be used for framework as well as general system administration.
e.g. net.bshlib is created for implementing networking related operations while remote.bshlib
is created for executing commands on a remote machine.
 
#### user
User libraries are used for users' business purpose(tests or tools), they can call functions
defined in framework libraries and always they are used only for test cases and user tools. 

### conf
#### framework
Environment variables are defined here which are used for framework.

#### user
Environment variables are defined here which are used for users' business purpose, please be
noted that we can re-defined framework environment variables here.

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

#### ut_tests
Please be noted that this is a sample for writing test cases. Please follow the
way to write your own test cases:
* config
  The config file defines all envrionment variables used for the test cases.
* xx.bshlib
  The library file defines all functions used for the test cases.
* setup
  The setup file will prepare the testing environment for the test cases.
* test cases
  Testing steps and expected results are defined. 
* cleanup
  The cleanup file will clean the testing environment after all test cases.
*Please never rename the config/setup/cleanup files.*

## Usage
1. On a local linux machine, clone moon_bshauto.
2. Deploy moon_bshauto to the remote nodes.
```
  # moon_bshauto/tools/deploy.sh
  Usage: deploy.sh -f host_file|-h host_list [-d path]
  host_file: file with host names or ips separated by new-line char.
  host_list: list of host names or ips separated by space.
  path: work home where the framework will be installed(/var/log by default).
  
  # moon_bshauto/tools/deploy.sh -h 192.168.78.78
```
3. Run test cases
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
4. Two ways to run tools:
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
