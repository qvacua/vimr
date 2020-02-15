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
    booleanParam('publish', true, 'Publish this release to Github?')
    stringParam('branch', 'develop', 'Branch to build; defaults to develop')
    stringParam('marketing_version', null, 'Eg "0.34.0". If "is_snapshot" is unchecked, you have to enter this.')
    textParam('release_notes', null, 'Release notes')
    booleanParam('is_snapshot', true)
    booleanParam('update_appcast', true)
    booleanParam('update_snapshot_appcast_for_release', true)
    booleanParam('use_cache_carthage', false)
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
