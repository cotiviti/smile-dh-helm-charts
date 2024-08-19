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

    chartVer = ChartVersion(ver)
    env.variables.current_smile_cdr_version = chartVer.CDRVersion()

    env.variables.current_helm_version = str(ver)

    env.variables.next_helm_patch_version = str(ver.bump_patch())
    env.variables.next_helm_minor_version = str(ver.bump_minor())
    env.variables.next_helm_major_version = str(ver.bump_major())

    env.variables.helm_repo_stable = "https://gitlab.com/api/v4/projects/40759898/packages/helm/stable"
    env.variables.helm_repo_devel = "https://gitlab.com/api/v4/projects/40759898/packages/helm/devel"


    version_info = [
        {
            'chart_version': '2.0.0',
            'cdr_versions': {
                'default': '2024.08.R01',
                'newest': '2024.08.R01',
                'oldest': '2023.08.R10'
            }
        },
        {
            'chart_version': '1.1.0',
            'cdr_versions': {
                'default': '2024.05.R03',
                'newest': '2024.05.R04',
                'oldest': '2023.05.R03'
            }
        },
        {
            'chart_version': '1.0.0',
            'cdr_versions': {
                'default': '2024.05.R03',
                'newest': '2024.05.R04',
                'oldest': '2023.05.R03'
            }
        }
    ]

class ChartVersion:
    def __init__(self, ver: semver.Version):
        initialCDRVersion = "2024.05.R03"
        self.cdrVersion = CDRVersion(initialCDRVersion)
        self.version = ver
        # Here we bump the CDR version for every major Helm Chart version.
        for bump in range(self.version.major - 1):
            self.cdrVersion.bump_major()

    def chartVersion(self):
        return str(self.version)

    def CDRVersion(self):
        return str(self.cdrVersion)



import re

class CDRVersion:
    def __init__(self, version: str):
        self.version_str = version
        self.year = 0
        self.month = 0
        self.patch = None
        self.pre = None
        self.gm = None
        self._parse_version()

    def _parse_version(self):
        # Regex patterns for parsing the version string
        major_patch_pattern = r'^(?P<year>\d{4})\.(?P<month>02|05|08|11)\.R(?P<patch>\d{2})$'
        pre_release_pattern = r'^(?P<year>\d{4})\.(?P<month>02|05|08|11)\.PRE-(?P<pre>\d+)$'
        gm_pattern = r'^(?P<year>\d{4})\.(?P<month>02|05|08|11)\.GM(?P<gm>\d+)$'

        if match := re.match(major_patch_pattern, self.version_str):
            self.year = int(match.group('year'))
            self.month = int(match.group('month'))
            self.patch = int(match.group('patch'))
        elif match := re.match(pre_release_pattern, self.version_str):
            self.year = int(match.group('year'))
            self.month = int(match.group('month'))
            self.pre = int(match.group('pre'))
        elif match := re.match(gm_pattern, self.version_str):
            self.year = int(match.group('year'))
            self.month = int(match.group('month'))
            self.gm = int(match.group('gm'))
        else:
            raise ValueError("Invalid version format")

    def bump_major(self):
        if self.month == 11:
            self.year += 1
            self.month = 2
        else:
            self.month += 3

        # Reset patch, pre, and gm versions
        self.patch = 1
        self.pre = None
        self.gm = None
        self._update_version_str()

    def bump_patch(self):
        # Increase the patch version
        if self.patch is None:
            raise ValueError("Cannot bump patch on a pre-release or GM version")
        self.patch += 1
        self._update_version_str()

    def _update_version_str(self):
        if self.patch is not None:
            self.version_str = f"{self.year:04}.{self.month:02}.R{self.patch:02}"
        elif self.pre is not None:
            self.version_str = f"{self.year:04}.{self.month:02}.PRE-{self.pre}"
        elif self.gm is not None:
            self.version_str = f"{self.year:04}.{self.month:02}.GM{self.gm}"

    def __str__(self):
        return self.version_str

    def __repr__(self):
        return f"<CDRVersion {self.version_str}>"
