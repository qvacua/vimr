def vimrReleaseBuild = 'vimr_release_build'
def vimrReleaseUpload = 'vimr_release_upload'
def vimrSnapshotBuild = 'vimr_snapshot_build'
def vimrSnapshotUpload = 'vimr_snapshot_upload'


def commonConfig(delegate) {
  def commonConfigClosure = {
    environmentVariables {
      env('PATH', '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin')
    }

    scm {
      git {
        remote { url 'https://github.com/qvacua/vimr.git' }
        branch '$branch_to_build'
        shallowClone true

        configure { git ->
          def submoduleCfg = git / 'submoduleCfg'
          submoduleCfg.@class = 'list'

          git / 'extensions' / 'hudson.plugins.git.extensions.impl.SubmoduleOption' {
              'disableSubmodules' false
              'recursiveSubmodules' true
              'trackingSubmodules' false
          }
        }
      }
    }
  }

  commonConfigClosure.resolveStrategy = Closure.DELEGATE_FIRST
  commonConfigClosure.delegate = delegate
  commonConfigClosure()
}

job {
  name vimrReleaseBuild

  logRotator(-1, 4, -1, -1)
  
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

job {
  name vimrSnapshotBuild
  
  logRotator(-1, 4, -1, -1)
  
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
