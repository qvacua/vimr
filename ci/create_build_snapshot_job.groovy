// Install the following plugins in addition to recommended plugins when installing Jenkins
// - Job DSL
// - AnsiColor

def buildSnapshotJob = freeStyleJob('vimr_build_snapshot')

buildSnapshotJob.with {
  description 'Builds a new snapshot of VimR and pushes the tag'

  logRotator {
    numToKeep(30)
  }

  parameters {
    stringParam('BRANCH', 'master', 'Branch to build; defaults to master')
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
