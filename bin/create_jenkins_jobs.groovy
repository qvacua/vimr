// Plugins to install
// Clone Workspace SCM Plug-in
// Environment Injector Plugin
// Job DSL
// Publish Over FTP (we don't create the upload jobs here)

def vimrReleaseBuild = 'vimr_release_build'
def vimrReleaseUpload = 'vimr_release_upload'
def vimrSnapshotBuild = 'vimr_snapshot_build'
def vimrSnapshotUpload = 'vimr_snapshot_upload'

def commonConfig(delegate) {
  delegate.with({
    logRotator(-1, 4, -1, -1)

    environmentVariables { env('PATH', '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin') }

    scm {
      git {
        remote { url 'https://github.com/qvacua/vimr.git' }
        branch '$branch_to_build'

        shallowClone true
        recursiveSubmodules true
      }
    }
  })
}

freeStyleJob(vimrReleaseBuild) {
  parameters {
    stringParam('branch_to_build', 'master', 'Branch to build')
  }

  commonConfig(delegate)

  steps {
    shell '''
pushd bin
npm install
popd
./bin/build_release
'''
  }

  publishers {
    archiveArtifacts 'build/**/*.tar.bz2, build/**/*checksum.txt, build/**/size.txt'
    publishCloneWorkspace 'build/**/*.tar.bz2'
    downstream vimrReleaseUpload
  }
}

freeStyleJob(vimrSnapshotBuild) {
  parameters {
    stringParam('branch_to_build', 'develop', 'Branch to build')
  }

  commonConfig(delegate)

  steps {
    shell '''
pushd bin
npm install
popd
./bin/build_snapshot
'''
  }

  publishers {
    archiveArtifacts 'build/**/*.tar.bz2'
    publishCloneWorkspace 'build/**/*.tar.bz2'
    downstream vimrSnapshotUpload
  }
}
