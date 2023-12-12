// Install the following plugins in addition to recommended plugins when installing Jenkins
// - Job DSL
// - AnsiColor

def buildSnapshotJob = freeStyleJob('vimr_build')

buildSnapshotJob.with {
  description 'Builds a new snapshot or a new release'

  logRotator {
    numToKeep(10)
  }

  parameters {
    stringParam('marketing_version', null, 'Eg "0.34.0". If "is_snapshot" is unchecked, you have to enter this.')
    booleanParam('is_snapshot', true)
    stringParam('branch', 'master', 'Branch to build; defaults to master')
    textParam('release_notes', null, 'Release notes')
    booleanParam('create_gh_release', false, 'Publish this release to Github?')
    booleanParam('upload', false, 'Upload VimR to Github?')
    booleanParam('update_appcast', false)
  }

  scm {
    git {
      remote {
        url('git@github.com:qvacua/vimr.git')
      }
      branch('*/${branch}')
    }
  }

  wrappers {
    colorizeOutput()
  }

  steps {
    shell('./bin/build_jenkins.sh')
  }

  publishers {
    archiveArtifacts {
      pattern('build/Build/Products/Release/**')
      onlyIfSuccessful()
    }
  }
}
