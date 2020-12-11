# VSCode-Remote-SSH

Deploy a remote development system for VS Code's Remote SSH on Fly.

<!---- cut here --->

## Rationale

When you get the need to develop but there's no machine to hand that's quite powerful enough, your next step may be to roll yourself a cloud instance and develop on there. With tools like VS Code's Remote SSH mode, remotely working with a development machine in the cloud can be a joy. 

But then you have to go through the entire provisioning process every time you want a fresh machine to work with. Which is why using Fly can make it simpler. This Appkata example is all about making that process completely automated. At the end of deploying it, you'll have a Fly instance with attached disk storage, running Ubuntu, accessible by you and using certificate-based authentication, with Docker and whatever packages you select.

## Using

Get the code by git cloning the repository:

```
git clone https://github.com/fly-examples/appkata-vscode-remote.git
```

Then cd into the `appkata-vscode-remote` directory and run the configure script.

```cmd
./configure.sh
```
```out
Enter desired app name or press return to have a name generated:
Enter disk size in GB or press return for default 10GB:
Use Docker on remote machine (y/n):y
Any extra packages:clang htop make
```

We'll pause here to review the only interactive part of the process.

* First, there's a request for an app-name which is used for the instance's hostname. If you don't need a particular name, just hit return and Fly will generate an appname.
* Then there's a request for the number of gigabytes of disk space you want attached to the instance. This will be your working space. Hit return to get the minimum (and default) of 10GB.
* If you want Docker's daemon and tools pre-installed, answer Y at the next question.
* You can add other Ubuntu packages to be pre-installed at this point. Hit return for none, or enter their names in a space-separated list.

Why is this pre-installation important you may ask. Remember that this is the image that we will start with and the image that Fly will reload when an instance is restarted or moved. Not pre-installing it means that, although you could install something, it would be completely transitory and disappear when the instance was restarted. Unless you made provision to install things on the persistent disk space (not simple for system packages). So thats why we ask about Docker and extra packages.

From this point on, the deployment process happens without intervention.

#### Creating the configuration

The script starts work by creating a template (`import.toml`) and using that to create a new Fly app. This template is  custom created and includes copies of the public keys of the user which are then used to authenticate SSH logins to the app later. This then automatically configures the app to work with SSH on port 10022 externally and port 22 internally.

```
Importing configuration from import.toml
Importing port 22
New app created
  Name         = crimson-bush-6560
  Organization = personal
  Version      = 0
  Status       =
  Hostname     = <empty>

App will initially deploy to lhr (London, United Kingdom) region

Wrote config file fly.toml
```
`
The created `fly.toml` file already has an entry in it for a persistent volume called data. That now needs to be created.

#### Creating a persistent volume

The script gets the region the app was created in (here `lhr`) and creates the volume in it.

```
        ID: p0Kg0L0JRGjBluq1PD
      Name: data
    Region: lhr
   Size GB: 10
Created at: 02 Dec 20 11:04 UTC
```

It is now able to go ahead and build the image for deployment.

#### Building the image

At this point, the script runs `fly deploy` which itself does two things; build the app's image and deploy the results.

The building is done by processing the `Dockerfile`.

```
Deploying crimson-bush-6560
==> Validating App Configuration
--> Validating App Configuration done
Services
TCP 10022 ⇢ 22

Deploy source directory '/Users/dj/temp/appkata-vscode-remote'
Docker daemon available, performing local build...
==> Building with Dockerfile
Using Dockerfile Builder: /Users/dj/temp/appkata-vscode-remote/Dockerfile
Step 1/17 : FROM ubuntu:bionic
 ---> 2c047404e52d
 ...
 ```

There's a lot more output that comes here with the creating and installation of all the packages required, along with any other packages requested. We've skipped it here, but rest assured we end up here next:

```
Step 17/17 : CMD ["/usr/sbin/sshd", "-D"]
 ---> Running in 765dba7b0c10
 ---> b63be4ff51c8
Successfully built b63be4ff51c8
Successfully tagged registry.fly.io/crimson-bush-6560:deployment-1606907053
--> Building with Dockerfile done
```

The next part sees the new image first pushed to the fly.io repository, and then after being processed and optimized, deployed to the Fly infrastructure.

```
Image: registry.fly.io/crimson-bush-6560:deployment-1606907053
Image size: 488 MB
==> Pushing Image
The push refers to repository [registry.fly.io/crimson-bush-6560]
...
deployment-1606907053: digest: sha256:99806ec0460487aaaa8d4899f02471e10c39e9d98a424efda58a9e63e7e2251d size: 2400
--> Done Pushing Image
==> Optimizing Image
--> Done Optimizing Image
==> Creating Release
Release v0 created
Deploying to : crimson-bush-6560.fly.dev

Monitoring Deployment
You can detach the terminal anytime without stopping the deployment

1 desired, 1 placed, 1 healthy, 0 unhealthy
--> v0 deployed successfully


To use in VS Code, tell the remote-ssh package to connect to dj@crimson-bush-6560.fly.dev:10022
```

The very last thing we are told is the address we need to give to VS Code when we do "Remote-SSH -> Connect to Host". Open VS Code, bring up the command line (Command/Control-Shift-P), enter `remote-ssh` and select `Connect to Host`. You'll be prompted to `Select configured SSH host or enter user@host`. We'll do the latter, and enter (as per our example) `dj@crimson-bush-6560.fly.dev:10022`. You'll be prompted to confirm the fingerprint of the machine you are connecting to (hit return) and then a new VS Code window will appear, with everything - file system, language server, tools and terminals running on the remote machine.


## Inside the process

Now, at this point, if you're happy launching your own VS Code SSH instances on Fly and don't need to know more you can go. If you are curious on how this example is built, then read on.

### The Dockerfile

The heart of many Fly apps is the Dockerfile, which creates the image that will be sent up to Fly to run. In this case, it uses Ubuntu Bionic as a base then:

* installs a number of essential packages (SSH server) and anything selected by the user as an extra package.
* creates a user with a selected name.
* gives that user sudo privileges.
* installs Docker components if they were requested
* copies over SSH server configuration and keys
* sets up the image to run






### Creating with a Template

### Finding the Region/Creating a Volume

### Deploying with Docker Arguments

