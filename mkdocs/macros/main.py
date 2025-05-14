"""
Mkdocs-macros module for Smile CDR docs site
"""
import semver
import re

version_info = [
        {
            'chart_version': '3.0.0',
            'cdr_versions': {
                'default': '2024.11.R05',
                'max': '2024.11.R05',
                'min': '2023.11.R01'
            }
        },
        {
            'chart_version': '2.0.0',
            'cdr_versions': {
                'default': '2024.08.R01',
                'max': '2024.08.R01',
                'min': '2023.08.R01'
            }
        },
        {
            'chart_version': '1.1.0',
            'cdr_versions': {
                'default': '2024.05.R03',
                'max': '2024.05.R04',
                'min': '2023.05.R01'
            }
        }
    ]

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

    # Autodetect current version
    # If the .VERSION file exists, then it was created by a Semantic Release job that ran prior to the docs job.
    # In that case, we want to use the new .VERSION. We cannot use the tag for this as it was not created for this commit.
    # If there is no .VERSION file, then Semantic Release did not bump the version. In that case it's safe to use the last git version tag.
    try:
        with open('.VERSION', 'r') as file:
            ver = semver.Version.parse(file.read())
    except:
        ver = semver.Version.parse(env.variables.git['short_tag'][1:])


    # chartVer = ChartVersion(ver).bump_major()
    chartVer = ChartVersion(ver)
    env.variables.current_smile_cdr_version = chartVer.CdrVersion()
    env.variables.current_smile_cdr_version_min = chartVer.CdrVersionMin()
    env.variables.current_helm_version = str(chartVer)
    # env.variables.current_helm_version = str(ver)

    preReleaseChartVer = chartVer.bump_minor()
    preReleaseChartVer.set_pre()
    env.variables.pre_release_smile_cdr_version = chartVer.CdrVersion()
    env.variables.pre_release_smile_cdr_version_min = chartVer.CdrVersionMin()
    env.variables.pre_release_helm_version = str(chartVer.bump_minor().set_pre())

    nextMajorChartVer = chartVer.bump_major()
    nextMajorChartVer.set_next_major()
    env.variables.next_major_smile_cdr_version = nextMajorChartVer.CdrVersion()
    env.variables.next_major_smile_cdr_version_min = nextMajorChartVer.CdrVersionMin()
    env.variables.next_major_helm_patch_version = str(chartVer.bump_patch())
    env.variables.next_major_helm_minor_version = str(chartVer.bump_minor())
    env.variables.next_major_helm_major_version = str(chartVer.bump_major())
    env.variables.next_major_helm_version = str(nextMajorChartVer.set_next_major())

    # env.variables.next_major_helm_patch_version = str(ver.bump_patch())
    # env.variables.next_major_helm_minor_version = str(ver.bump_minor())
    # env.variables.next_major_helm_major_version = str(ver.bump_major())
    
    betaChartVer = nextMajorChartVer.bump_major()
    betaChartVer.set_beta()
    env.variables.beta_smile_cdr_version = betaChartVer.CdrVersion()
    env.variables.beta_smile_cdr_version_min = betaChartVer.CdrVersionMin()
    env.variables.beta_helm_major_version = str(nextMajorChartVer.bump_major())
    env.variables.beta_helm_version = str(betaChartVer.set_beta())

    alphaChartVer = betaChartVer.bump_major()
    alphaChartVer.set_alpha()
    env.variables.alpha_smile_cdr_version = alphaChartVer.CdrVersion()
    env.variables.alpha_smile_cdr_version_min = alphaChartVer.CdrVersionMin()
    env.variables.alpha_helm_major_version = str(betaChartVer.bump_major())
    env.variables.alpha_helm_version = str(alphaChartVer.set_alpha())
    

    env.variables.helm_repo_stable = "https://gitlab.com/api/v4/projects/40759898/packages/helm/stable"
    env.variables.helm_repo_devel = "https://gitlab.com/api/v4/projects/40759898/packages/helm/devel"
    env.variables.helm_repo_pre = "https://gitlab.com/api/v4/projects/40759898/packages/helm/pre-release"
    env.variables.helm_repo_next = "https://gitlab.com/api/v4/projects/40759898/packages/helm/next-major"
    env.variables.helm_repo_beta = "https://gitlab.com/api/v4/projects/40759898/packages/helm/beta"
    env.variables.helm_repo_alpha = "https://gitlab.com/api/v4/projects/40759898/packages/helm/alpha"



    env.variables.previous_versions_table = ""

    for version in version_info:
        line = f'| v{version["chart_version"]} | `{version["cdr_versions"]["default"]}` | `{version["cdr_versions"]["min"]}` |\n'
        env.variables.previous_versions_table += line
class ChartVersion:
    

    def __init__(self, ver: semver.Version):
        initialCdrVersion = "2024.05.R03"
        self.cdrVersions = {}
        self.version = ver
        """
        Automatically determine the CDR version for a given Helm Chart Version

        Starting from `initialCdrVersion`, bump the CDR major version by 1 for every major version
        of the Helm Chart since v1.x

        This will automatically enforce the correlation between major Helm Chart versions and
        Smile CDR GA releases.

        However, it will NOT correlate patch level releases of the Helm Chart to patch level
        versions of the Smile CDR. For this, we can refer to the provided object that contains
        known release mappings.
        """
        
        # Check the predefined mappings to see if the current Helm Chart version is defined. If so,
        # use that cdrVersion.

        for version in version_info:
            if version["chart_version"] == self.version:
                defaultCdrVersion = version["cdr_versions"]["default"]
                CdrVersionMax = version["cdr_versions"]["max"]
                CdrVersionMin = version["cdr_versions"]["min"]
                # self.cdrVersion.setVersion(defaultCdrVersion)
                self.cdrVersions["default"] = CdrVersion(defaultCdrVersion)
                self.cdrVersions["max"] = CdrVersion(CdrVersionMax)
                self.cdrVersions["min"] = CdrVersion(CdrVersionMin)

        # If no predefined version was found, determine the version automatically based on the
        # initialCdrVersion and the number of Helm Chart major releases.
        if not self.cdrVersions:
            self.cdrVersions["default"] = CdrVersion(initialCdrVersion)
            self.cdrVersions["min"] = CdrVersion(initialCdrVersion)
            # Cycle through Helm Chart major versions and bump the CDR GA release once for each.
            for bump in range(self.version.major - 1):
                self.cdrVersions["default"].bump_major()
                self.cdrVersions["min"].bump_major()
            self.cdrVersions["min"].set_min()

    def __str__(self):
        return str(self.version)

    def major(self):
        return str(self.version.major)
    def minor(self):
        return str(self.version.minor)
    def patch(self):
        return str(self.version.patch)

    def CdrVersion(self):
        return str(self.cdrVersions["default"])
    
    def CdrVersionMax(self):
        return str(self.cdrVersions["max"])
    
    def CdrVersionMin(self):
        return str(self.cdrVersions["min"])

    def bump_major(self, pre: bool = False):
        # Returns a new ChartVersion object
        return ChartVersion(self.version.bump_major())

    def bump_minor(self, pre: bool = False):
        # Returns a new ChartVersion object
        return ChartVersion(self.version.bump_minor())

    def bump_patch(self, pre: bool = False):
        # Returns a new ChartVersion object
        return ChartVersion(self.version.bump_patch())

    def set_pre(self):
        self.cdrVersions["default"].set_pre()
        return ChartVersion(self.version.replace(prerelease="pre.*"))
    
    def set_next_major(self):
        self.cdrVersions["default"].set_pre()
        return ChartVersion(self.version.replace(prerelease="next-major.*"))
    
    def set_beta(self):
        self.cdrVersions["default"].set_pre()
        return ChartVersion(self.version.replace(prerelease="beta.*"))
    
    def set_alpha(self):
        self.cdrVersions["default"].set_pre()
        return ChartVersion(self.version.replace(prerelease="alpha.*"))


class CdrVersion:
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
    
    # Set this version to the R01 patch for the GA release from 1 year earlier
    def set_min(self):
        self.year -= 1
        self.patch = 1
        self.pre = None
        self.gm = None
        self._update_version_str()

    # def set_version(self, version: str):
    #     self.version_str = version
    #     self.patch = None
    #     self.pre = 1
    #     self.gm = None
    #     self._update_version_str()

    def set_pre_old(self):
        self.patch = None
        self.pre = 1
        self.gm = None
        self._update_version_str()
    
    def set_pre(self):
        self.patch = None
        self.pre = "*"
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
        return f"<CdrVersion {self.version_str}>"
