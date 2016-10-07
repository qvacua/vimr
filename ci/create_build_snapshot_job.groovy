// Install the following plugins in addition to recommended plugins when installing Jenkins
// - Job DSL
// - AnsiColor
//
// And set the "Markup Formatter" in "Manage Jenkins -> Configure Global Security" to "Safe HTML".

def buildSnapshotJob = freeStyleJob('vimr_build_snapshot')

buildSnapshotJob.with {
  description '''\
Builds a new snapshot of VimR and pushes the tag:<br>
<ul>
  <li>
    <a href="lastSuccessfulBuild/artifact/build/Release/">Last successful Release</a>
  </li>
</ul>
'''

  logRotator {
    numToKeep(30)
  }

  parameters {
    stringParam('BRANCH', 'master', 'Branch to build; defaults to master')
    textParam('RELEASE_NOTES', null, 'Release notes')
  }

  scm {
    git {
      remote {
        url('git@github.com:qvacua/vimr.git')
      }
      branch('*/${BRANCH}')
    }
  }

  wrappers {
    timestamps()
    colorizeOutput()
  }

  steps {
    shell('./bin/build_snapshot.sh')
  }

  publishers {
    archiveArtifacts {
      pattern('build/Release/**')
      onlyIfSuccessful()
    }
  }
}
