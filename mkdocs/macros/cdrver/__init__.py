# cdrver.py

import re

class CDRVersion:
    def __init__(self, year, month, patch=1, pre_release=None, release_candidate=None):
        self.year = year
        self.month = month
        self.patch = patch
        self.pre_release = pre_release
        self.release_candidate = release_candidate

    @classmethod
    def from_string(cls, version_str):
        pattern = r'(\d{4})\.(0[258]|11)\.(?:R(\d{2})|PRE-(\d+)|GM(\d+))'
        match = re.match(pattern, version_str)
        if not match:
            raise ValueError(f"Invalid version string: {version_str}")

        year, month, patch, pre_release, release_candidate = match.groups()
        year = int(year)
        month = int(month)
        patch = int(patch) if patch else 1
        pre_release = int(pre_release) if pre_release else None
        release_candidate = int(release_candidate) if release_candidate else None

        return cls(year, month, patch, pre_release, release_candidate)

    def bump_major(self):
        self.patch = 1
        self.pre_release = None
        self.release_candidate = None

    def bump_patch(self):
        self.patch += 1

    def __str__(self):
        if self.pre_release is not None:
            return f"{self.year}.{self.month:02}.PRE-{self.pre_release}"
        elif self.release_candidate is not None:
            return f"{self.year}.{self.month:02}.GM{self.release_candidate}"
        else:
            return f"{self.year}.{self.month:02}.R{self.patch:02}"

    def to_tuple(self):
        return (self.year, self.month, self.patch, self.pre_release, self.release_candidate)

    def is_pre_release(self):
        return self.pre_release is not None

    def is_release_candidate(self):
        return self.release_candidate is not None
