"""Collects every course's lecture script and study material."""
from .ei_foundations_etc import COURSES as A
from .wellbeing_etc import COURSES as B
from .teams_etc import COURSES as C

COURSES = {**A, **B, **C}
