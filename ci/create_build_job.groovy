// Install the following plugins in addition to recommended plugins when installing Jenkins
// - Job DSL
// - AnsiColor
//
// And set the "Markup Formatter" in "Manage Jenkins -> Configure Global Security" to "Safe HTML".

def buildSnapshotJob = freeStyleJob('vimr_build')

buildSnapshotJob.with {
  description '''\
Builds a new snapshot of VimR and pushes the tag:<br>
<ul>
  <li>
    <a href="lastSuccessfulBuild/artifact/build/Build/Products/Release/">Last successful Release</a>
  </li>
</ul>
'''

  logRotator {
    numToKeep(10)
  }

  parameters {
    booleanParam('PUBLISH', true, 'Publish this release to Github?')
    stringParam('BRANCH', 'develop', 'Branch to build; defaults to develop')
    stringParam('MARKETING_VERSION', null, 'If IS_SNAPSHOT is unchecked, you have to enter this.')
    textParam('RELEASE_NOTES', null, 'Release notes')
    booleanParam('IS_SNAPSHOT', true)
    booleanParam('UPDATE_APPCAST', true)
    booleanParam('UPDATE_SNAPSHOT_APPCAST_FOR_RELEASE', true)
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
    colorizeOutput()
  }

  steps {
    shell('./bin/build.sh')
  }

  publishers {
    archiveArtifacts {
      pattern('build/Build/Products/Release/**')
      onlyIfSuccessful()
    }
  }
}
