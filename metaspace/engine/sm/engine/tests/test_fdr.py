from itertools import product
from unittest.mock import patch

import pandas as pd
from pandas.util.testing import assert_frame_equal

from sm.engine.annotation.fdr import FDR
from sm.engine.formula_parser import format_modifiers

FDR_CONFIG = {'decoy_sample_size': 2}


@patch('sm.engine.annotation.fdr.DECOY_ADDUCTS', ['+He', '+Li'])
def test_fdr_decoy_adduct_selection_saves_corr():
    fdr = FDR(
        fdr_config=FDR_CONFIG,
        chem_mods=[],
        neutral_losses=[],
        target_adducts=['+H', '+K', '[M]+'],
        analysis_version=1,
    )

    exp_target_decoy_df = pd.DataFrame(
        [
            ('H2O', '+H', '+He'),
            ('H2O', '+H', '+Li'),
            ('H2O', '+K', '+He'),
            ('H2O', '+K', '+Li'),
            ('H2O', '', '+He'),
            ('H2O', '', '+Li'),
        ],
        columns=['formula', 'tm', 'dm'],
    )

    fdr.decoy_adducts_selection(target_formulas=['H2O'])

    assert_frame_equal(
        fdr.td_df.sort_values(by=['formula', 'tm', 'dm']).reset_index(drop=True),
        exp_target_decoy_df.sort_values(by=['formula', 'tm', 'dm']).reset_index(drop=True),
    )


def test_estimate_fdr_returns_correct_df():
    fdr = FDR(
        fdr_config=FDR_CONFIG,
        chem_mods=[],
        neutral_losses=[],
        target_adducts=['+H'],
        analysis_version=1,
    )
    fdr.fdr_levels = [0.2, 0.8]
    fdr.td_df = pd.DataFrame(
        [['H2O', '+H', '+Cu'], ['H2O', '+H', '+Co'], ['C2H2', '+H', '+Ag'], ['C2H2', '+H', '+Ar']],
        columns=['formula', 'tm', 'dm'],
    )

    msm_df = pd.DataFrame(
        [
            ['H2O', '+H', 0.85],
            ['C2H2', '+H', 0.5],
            ['H2O', '+Cu', 0.5],
            ['H2O', '+Co', 0.5],
            ['C2H2', '+Ag', 0.75],
            ['C2H2', '+Ar', 0.0],
        ],
        columns=['formula', 'modifier', 'msm'],
    )
    exp_sf_df = pd.DataFrame(
        [['H2O', '+H', 0.2], ['C2H2', '+H', 0.8]], columns=['formula', 'modifier', 'fdr']
    )

    assert_frame_equal(fdr.estimate_fdr(msm_df), exp_sf_df)


def test_estimate_fdr_digitize_works():
    fdr_config = {**FDR_CONFIG, 'decoy_sample_size': 1}
    fdr = FDR(
        fdr_config=fdr_config,
        chem_mods=[],
        neutral_losses=[],
        target_adducts=['+H'],
        analysis_version=1,
    )
    fdr.fdr_levels = [0.4, 0.8]
    fdr.td_df = pd.DataFrame(
        [['C1', '+H', '+Cu'], ['C2', '+H', '+Ag'], ['C3', '+H', '+Cl'], ['C4', '+H', '+Co']],
        columns=['formula', 'tm', 'dm'],
    )

    msm_df = pd.DataFrame(
        [
            ['C1', '+H', 1.0],
            ['C2', '+H', 0.75],
            ['C3', '+H', 0.5],
            ['C4', '+H', 0.25],
            ['C1', '+Cu', 0.75],
            ['C2', '+Ag', 0.3],
            ['C3', '+Cl', 0.25],
            ['C4', '+Co', 0.1],
        ],
        columns=['formula', 'modifier', 'msm'],
    )
    exp_sf_df = pd.DataFrame(
        [['C1', '+H', 0.4], ['C2', '+H', 0.4], ['C3', '+H', 0.4], ['C4', '+H', 0.8]],
        columns=['formula', 'modifier', 'fdr'],
    )

    assert_frame_equal(fdr.estimate_fdr(msm_df), exp_sf_df)


def test_ions():
    formulas = ['H2O', 'C5H2OH']
    target_adducts = ['+H', '+Na']
    decoy_sample_size = 5
    fdr_config = {**FDR_CONFIG, 'decoy_sample_size': decoy_sample_size}

    fdr = FDR(
        fdr_config=fdr_config,
        chem_mods=[],
        neutral_losses=[],
        target_adducts=target_adducts,
        analysis_version=1,
    )
    fdr.decoy_adducts_selection(target_formulas=['H2O', 'C5H2OH'])
    ions = fdr.ion_tuples()

    assert type(ions) == list
    # total number varies because different (formula, modifier) pairs may receive the same (formula, decoy_modifier) pair
    assert (
        len(formulas) * decoy_sample_size + len(formulas) * len(target_adducts)
        < len(ions)
        <= len(formulas) * len(target_adducts) * decoy_sample_size
        + len(formulas) * len(target_adducts)
    )
    target_ions = [(formula, adduct) for formula, adduct in product(formulas, target_adducts)]
    assert set(target_ions).issubset(set(map(tuple, ions)))


def test_chem_mods_and_neutral_losses():
    formulas = ['H2O', 'C5H2OH']
    chem_mods = ['-H+C']
    neutral_losses = ['-O', '-C']
    target_adducts = ['+H', '+Na', '[M]+']
    target_modifiers = [
        format_modifiers(cm, nl, ta)
        for cm, nl, ta in product(['', *chem_mods], ['', *neutral_losses], target_adducts)
    ]
    decoy_sample_size = 5
    fdr_config = {**FDR_CONFIG, 'decoy_sample_size': decoy_sample_size}

    fdr = FDR(
        fdr_config=fdr_config,
        chem_mods=chem_mods,
        neutral_losses=neutral_losses,
        target_adducts=target_adducts,
        analysis_version=1,
    )
    fdr.decoy_adducts_selection(target_formulas=['H2O', 'C5H2OH'])
    ions = fdr.ion_tuples()

    assert type(ions) == list
    # total number varies because different (formula, modifier) pairs may receive the same (formula, decoy_modifier) pair
    min_count = len(formulas) * len(target_modifiers)
    max_count = len(formulas) * len(target_modifiers) * (1 + decoy_sample_size)
    assert min_count < len(ions) <= max_count
    target_ions = list(product(formulas, target_modifiers))
    assert set(target_ions).issubset(set(map(tuple, ions)))
