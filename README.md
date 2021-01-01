# VSCode-Remote

Deploy a remote development system for VS Code's Remote SSH on Fly.

<!---- cut here --->

## Rationale

When you get the need to develop but there's no machine to hand that's quite powerful enough, your next step may be to roll yourself a cloud instance and develop on there. With tools like VS Code's Remote SSH mode, remotely working with a development machine in the cloud can be a joy. 

But then you have to go through the entire provisioning process every time you want a fresh machine to work with. Which is why using Fly can make it simpler. This example is all about making that process completely automated. At the end of deploying it, you'll have a Fly instance with attached disk storage, running Ubuntu, accessible by you and using certificate-based authentication, with Docker and whatever packages you select.

## Using

Get the code by git cloning the repository:

```
git clone https://github.com/fly-examples/vscode-remote.git
```

Then cd into the `vscode-remote` directory and run the configure script.

```cmd
./configure.sh
```
```out
Enter desired app name or press return to have a name generated:
Enter desired organization name or press return to use your personal org:
Enter disk size in GB or press return for default 10GB:
Use Docker on remote machine (y/n):y
Any extra packages:clang htop make
```

We'll pause here to review the only interactive part of the process.

* First, there's a request for an app-name which is used for the instance's hostname. If you don't need a particular name, just hit return and Fly will generate an appname.
* That's followed by a request for an organization. Just hit return to put it into your personal organization.
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

Deploy source directory '/Users/dj/temp/vscode-remote'
Docker daemon available, performing local build...
==> Building with Dockerfile
Using Dockerfile Builder: /Users/dj/temp/vscode-remote/Dockerfile
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
* gives that user `sudo` privileges.
* installs Docker components if they were requested
* copies over SSH server configuration and keys
* sets up the image to run

The important part here is that variables, `USER`, `USE_DOCKER` and `EXTRA_PKGS` are used to configure some of that build behavior.

### The Script

The `configure.sh` script is responsible for getting the values of those variables. It asks the user running it for settings for the various values. It also asks for an appname (as `$appname`), an organization (as `$orgname`), and a disk size for the attached volume. Finally, it gathers the user's SSH public keys into a single string called AUTHORIZED_KEYS. With all the values acquired, the script can create the app.

### Creating with a Template

To create the app, the script writes out a file called `import.toml`. It's a template for what we would like in our application when we create it. It sets up SSH's port 22 to appear as port 10022, adds a mount for a disk volume, and passes SSH AUTHORIZED_KEYS as an environment variable.

Then it runs:

```
fly init $appname --import import.toml --org $orgname --overwrite
```

This creates an app with the user's requested app name and organization and then imports the `import.toml` file to configure it. It places the app in the user's `personal` organization. Finally, an `--overwrite` flag means this command will overwrite existing `fly.toml` files without querying the user.

### Finding the Region/Creating a Volume

Now, this script needs to create a volume in the same region as the app to provide storage for it. While humans can easily read the the output saying which region the app has been created in, it's currently a little harder for scripts. That's where this snippet comes in:

```
REGION=`fly regions list --json | awk '/"Code"/ { sub(/\ *"Code\": \"/ , "")
sub(/",/,"")
print }'`
```

It runs the `fly regions list` command but with the `--json` flag which makes the output somewhat more processable. It then uses `awk` (a fine Unix command) to extract out the region code from the line which reads `"Code": "lhr",`. It's that value it saves into the REGION variable ready for when it runs:

```
fly volumes create data --region $REGION $disksize
```

Which creates the storage volume.

### Deploying with Docker Arguments

At this point in the script we are ready to deploy with `fly deploy` but we still have our `USER`, `USE_DOCKER` and `EXTRA_PKGS` arguments to pass. The command line looks like this:

```
fly deploy --build-arg USER=$(whoami) --build-arg EXTRA_PKGS="$extrapackages" $usedocker 
```

The `--build-arg` flag takes a name=value pairing as its parameter. The first build-arg sets `USER` to the value of the current user's name. The second build-arg sets `EXTRA_PKGS` to the value of the $extrapackages variable; notice that it is surrounded in quotes are the list of extra packages will likely contain spaces which the shell would process. 

Finally, we have `$usedocker` on its own, but that's because, if you scan to the top of the script, you'll see that it the user answers "Yes" to the question, the value of $usedocker is set to "--build-arg USE_DOCKER=y" (if they answer no, then $usedocker is just an empty string). 

As you can see, there's a lot of ways to build up your build arguments. Consult your shell and Dockerfile references for more.

Once run, the command will build, using the Dockerfile and build-args, an image which will then be deployed onto the Fly infrastructure.

The only thing left is the tell the user how to connect and what address to use.  

```
echo "To use in VS Code, tell the remote-ssh package to connect to $(whoami)@$(fly info --host):10022"
```

The `fly info --host` is an easy way to get the host name of your deployment for connection strings.

## Discuss

* You can discuss this example on the [vscode-remote example](https://community.fly.io/t/a-vscode-example-for-fly/460) topic on community.fly.io.



