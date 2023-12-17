* Install Jenkins (via brew)
* Install plugins
    - Job DSL
    - AnsiColor
* Set the `git` binary in *Manage Jenkins* -> *Global Tool Configuration*
* Set `PATH` for Jenkins (necessary for e.g. `git-lfs`) in *Manage Jenkins* -> *Configure System* -> *Global properties* -> *Environment variables"
* Add a free style job `vimr_setup_jobs` with one step to process a Job DSL file at `ci/create_build_job.groovy`.
  - Approve script at *Manager Jenkins* -> *In-process Script Approval*.

---

To test the job creation using local git repository, use `file:///Users/.../vimr-repo` as repository and add "-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" to `/opt/homebrew/opt/jenkins/bin/jenkins`:

```bash
#!/bin/bash
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home}"
exec "${JAVA_HOME}/bin/java" "-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" "-jar" "/opt/homebrew/Cellar/jenkins/2.435/libexec/jenkins.war" "$@"
```

