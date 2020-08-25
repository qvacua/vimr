from string import Template

# language=bash
package_command = Template(
    """
pushd "${parent_of_install_path}" >/dev/null
tar cjvf "${package_name}.tar.bz2" "${package_name}"
popd >/dev/null
"""
)
