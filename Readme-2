[![Build Status](https://travis-ci.com/gepardec/openshift-builder-maven.svg?branch=master)](https://travis-ci.com/gepardec/openshift-builder-maven)
![Maintenance](https://img.shields.io/maintenance/yes/2019)
![Docker Pulls](https://img.shields.io/docker/pulls/gepardec/s2i-builder-maven)
![GitHub](https://img.shields.io/github/license/gepardec/openshift-builder-maven)
<p align="right">
<img alt="gepardec" width=100px src="./.images/gepardec.png">
</p>
<br>
<br>
<p align="center">
<img alt="Logo" width=300px src="./.images/repo-logo.png">
</p>

 Here you will find everything to build our **S2I Maven Builder** which is classified as a custom **S2I Image Builder** (yellow box). In addition we will go through the the process of setting up a proper chained build visualized by the graphic below and deploy the resulting minimal image containing our artefact and runtime in an OpenShift / OKD cluster. 

We will show case the benefits of a our **S2I Maven Builder**. Our builder will be able to build java based git repositories from source with maven if a pom.xml is found. We will base our example on the hello world application provided by [wildlfy/quickstart](https://github.com/wildfly/quickstart). In addition we will briefly go through the benefits of using so called chained builds.

<p align="center">
<img width=640px alt="Best practice build via chained Build in OpenShift" src="./.images/chained-build.png">
</p>

---

# Use Case Scenario

We have our application source code available in a git repository ([wildlfy/quickstart](https://github.com/wildfly/quickstart)), we would like to containerize the application and run it with Wildfly as our runtime environment in OpenShift or OKD. 

**Main objectives**
* create an image that can run our application
* reduce image size to minimize transfer and deployment time
* application source code should not be part of the final image
* no unnecessary packages are allowed to keep the potential attack surface minimal
* container needs to be capable to run with a random UID (no root in runtime image allowed)

**Bonus objectives**
* the faster we can build the happier is our user base
* robust builds: if we can't build fast we should at least be able to build

**Our restrictions**
* we are not allowed to alter any elements in the source code repository

**Prerequisits**
* access to an OpenShift or OKD cluster

---

## Implementation 1: Satisfy Main Objectives

### 1) Create a new project
Let us create a new project in OpenShift to store all our resources related to the **S2I Maven Builder** and the hello world application.

```
oc new-project s2i-builder-maven \
     --display-name="S2I Maven Builder" \
     --description="This project contains all resources to build the S2I Maven Builder and use 
                    the builder to compile and run the hello world application. The hello world
                    application used here is available on github (wildfly/quickstart)."
```

### 2) create the builder image 
Let's build the **S2I Maven Builder** image from its repository and name it `s2i-builder-maven`. This will create a BuildConfig and an ImageStream named `s2i-builder-maven` and trigger the the first build of our image. 

```
oc new-build https://github.com/gepardec/openshift-builder-maven#1.0.0 --name=s2i-builder-maven
```

**Hint:** `#1.0.0` at the end of the repository url specifies a tag or branch. Providing a tag or a branch name is optional and if nothing is specified `master` will be selected.

### 3) use the builder to build your artefact
Now we have got our first component in place: our **S2I Maven Builder** `s2i-builder-maven`. Next we will use our newly created builder image to build our hello world application artefact from source with the builder's S2I scripts. 

**Pitfall:** Since our hello world application has its `pom.xml` in `helloworld/pom.xml` we could set `contextDir=helloworld`. However, `helloworld/pom.xml` refers to a `pom.xml` which resides in the root directory of the git repository. Here we got an issue with the current implementation of **contextDir**. As specified in the OpenShift 4.2 documentation (https://docs.openshift.com/container-platform/4.2/builds/creating-build-inputs.html):

> any input content that resides outside of the **contextDir** will be ingored by the build. 

That translates to `../pom.xml` not found for us, since it resides outside of the specified **contextDir**.

For this reason our custom build image provides an additional environment variable  `BUILDER_MVN_OPTIONS` that does not have the above mentioned limitation.

In short we will use our `s2i-builder-maven` to build wildfly/quickstart tagged 18.0.0.Final and call it `binary-artefact`. Our application `pom.xml` resides in `helloworld/pom.xml`. Therefore we will use the environment variable `BUILDER_CONTEXT_DIR` to set our context directory acordingly. In addition we will set `BUILDER_MVN_OPTIONS` to use the openshift profile specified in the `pom.xml`.

```
oc new-build s2i-builder-maven~https://github.com/wildfly/quickstart#18.0.0.Final \
     --name=binary-artefact  \
     --env=BUILDER_CONTEXT_DIR=helloworld \
     --env=BUILDER_MVN_OPTIONS="-P openshift"
```

Take a break, without optimization this will take about 10 minutes depending on your internet connection.

**Hint:** With `BUILDER_MVN_OPTIONS` you can provide any maven option that can be provided like this: `mvn clean package ${BUILDER_MVN_OPTIONS}`

### 4) Combine artefact with runtime
Now we have an image called `binary-artefact` that contains our application war in `/deployments/helloworld/target/ROOT.war` and our source code. To combine our artefact with a runtime environment we will copy only the artefact from the `binary-artefact` image to our new `runtime` image that we build via an inline specified dockerfile.

```
oc new-build --name=runtime --docker-image=jboss/wildfly \
     --source-image=binary-artefact \
     --source-image-path=/deployments/target/ROOT.war:. \
     --dockerfile=$'FROM jboss/wildfly\nCOPY ROOT.war /opt/jboss/wildfly/standalone/deployments/ROOT.war'
```

In short we have an image with our binary artefact (ROOT.war), an image with wildfly and with the build specified above we define an inline dockerfile that copies the artefact from the source image into our new runtime image.

<p align="center">
<img width=580px alt="Inline specified dockerfile to combine runtime and artefact" src="./.images/runtime-build.png">
</p>

### 5) Deploy the application
The heavy lifting is done. We have created our final image called `runtime`. Next we want to deploy it as `hello-world`.

```
oc new-app runtime --name=hello-world
```

### 6) Expose the application
In order to access our application from outside the cluster we still need to expose our `hello-world` sevice via a route.

```
oc expose svc/hello-world
```

### 7) Access the application
You can now access your application through your browser by entering the url that following command provides.

```
oc describe route/hello-world | grep "Requested Host:"
```

**Hint:** all commands executed in Implementation Scenario 1 can be run by executing: `usecase.sh`

---

## Implementation 2: Satisfy Main Objectives + Bonus Objectives

In order to archive our bonus objectives we need to build and deploy our application faster. 
Maven build typically fetches it dependencies from remote repositories such as maven central.
Fetching those dependencies over the internet with every build is not performant enough.
We can speed up the process by mirroring the required remote repositories in our infrastructure and use our local repositories instead.

To archive this we will need a Nexus or another product with the capability to proxy the required remote repositories already set up.

To speed up our `binary-artefact` build we can set our own maven mirror(s) via a dedicated environment variable. 
In short we **replace step 3 from Implementation 1** with

```
oc new-build s2i-builder-maven~https://github.com/wildfly/quickstart#18.0.0.Final \
     --name=binary-artefact \
     --env=BUILDER_MVN_MIRROR="*|https:/my-maven-mirror/path/to/maven-public/" \
     --env=BUILDER_MVN_MIRROR_ALLOW_FALLBACK=true
```

**Hint:** you can specify multiple maven mirrors via the `BUILDER_MVN_MIRROR` variable. More information on how to do that can be found in the section **Available Environment Variables in S2I Maven Builder**.

**Hint:** we have introduced an additional environment variable `BUILDER_MVN_MIRROR_ALLOW_FALLBACK` which can be set to `true` or `false`. If set to `false` the build will fail if the specified mirror is unavailable. `true` on the other hand will fall back to the repositories specified in the pom.xml and build slowly instead. 

---

# Available Environment Variables in S2I Maven Builder

**BUILDER_MVN_OPTIONS** ... can be used to add additional option to the maven execution. <br>

```
BUILDER_MVN_OPTIONS="-DskipTests"
```

**BUILDER_CONTEXT_DIR** ... can be used to define the location of the pom file within the git repository 
                    when the entire folder structure of the repository is required. Otherwise use 
                    contextDir in your buildconfig. e.g. to use helloworld/pom.xml you can set

```
BUILDER_CONTEXT_DIR=helloworld
```

**BUILDER_MVN_MIRROR**  ... can be used to specify maven mirror repositories <br>
                    a maven repository mirroring all required dependencies can be specified via: 
                    
```
*|http:/my-mirror.com/path/to/repo
```

multiple mirrors can be specified such that mirror-A is used for central and 
mirror-B is used for jboss: 

```
central|http:/mirror-A/path/to/repo;jboss|http:/mirror-B/path/to/repo
```

**BUILDER_MVN_MIRROR_ALLOW_FALLBACK** ... `true` / `false`; default is `false` <br>
     `false` ... fail if mirror is unavailable <br>
     `true`  ... fall back to maven repositories specified in pom.xml if 
                 mirror is unavailable

---

## Sources
* https://blog.openshift.com/chaining-builds/
* https://dzone.com/articles/how-to-create-a-builder-image-with-s2i
* https://maven.apache.org/guides/mini/guide-mirror-settings.html
* https://docs.openshift.com/container-platform/4.2/builds/creating-build-inputs.html
