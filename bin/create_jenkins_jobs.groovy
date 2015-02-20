def vimrReleaseBuild = 'vimr_release_build'
def vimrReleaseUpload = 'vimr_release_upload'
def vimrSnapshotBuild = 'vimr_snapshot_build'
def vimrSnapshotUpload = 'vimr_snapshot_upload'


def scmConfig(delegate) {
  def scmConfigClosure = {
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

  scmConfigClosure.resolveStrategy = Closure.DELEGATE_FIRST
  scmConfigClosure.delegate = delegate
  scmConfigClosure()
}

job {
  name vimrReleaseBuild

  logRotator(-1, 4, -1, -1)
  
  parameters {
    stringParam('branch_to_build', 'master', 'Branch to build')
  }

  scmConfig(delegate)

  steps {
    shell './bin/build_release'
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

  scmConfig(delegate)

  steps {
    shell './bin/build_snapshot'
  }

  publishers {
    archiveArtifacts 'build/**/*.tar.bz2'
    publishCloneWorkspace 'build/**/*.tar.bz2'
    downstream vimrSnapshotUpload
  }
}
