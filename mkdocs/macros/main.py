"""
Mkdocs-macros module for Smile CDR docs site
"""
import semver

def define_env(env):
    """
    This is the hook for defining variables, macros and filters

    - variables: the dictionary that contains the environment variables
    - macro: a decorator function, to declare a macro.
    - filter: a function with one of more arguments,
        used to perform a transformation
    """

    # NOTE: you may also treat env.variables as a namespace,
    #       with the dot notation:
    ver = semver.Version.parse(env.variables.git['short_tag'][1:])

    env.variables.current_helm_version = str(ver)

    env.variables.next_helm_patch_version = str(ver.bump_patch())
    env.variables.next_helm_minor_version = str(ver.bump_minor())
    env.variables.next_helm_major_version = str(ver.bump_major())

    env.variables.helm_repo_stable = "https://gitlab.com/api/v4/projects/40759898/packages/helm/stable"
    env.variables.helm_repo_devel = "https://gitlab.com/api/v4/projects/40759898/packages/helm/devel"
