:- module(test_scasp,
          [ test_scasp/0,
            qtest_scasp/0,
            run_test/2                  % +File, +Options
          ]).
:- set_prolog_flag(optimise, true).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(main)).
:- use_module(library(option)).
:- use_module(library(test_cover)).
:- use_module(library(time)).

scasp_dir(SCASPDir) :-
    source_file(scasp_dir(_), File),
    file_directory_name(File, TestDir),
    file_directory_name(TestDir, SCASPDir).

:- multifile
    user:file_search_path/2.
:- dynamic covers/3.
user:file_search_path(scasp, SCASPDir) :-
    scasp_dir(SCASPDir).
user:file_search_path(library, scasp(prolog)).

:- use_module(library(lists), [member/2]).
:- use_module(library(main), [main/0, argv_options/3]).
:- use_module(library(option), [option/3, option/2]).
:- use_module(library(time), [call_with_time_limit/2]).

:- use_module(library(scasp/ops)).
:- use_module(library(scasp/compile)).
:- use_module(library(scasp/solve)).
:- use_module(library(scasp/output)).
:- use_module(library(scasp/stack)).
:- use_module(library(scasp/model)).
:- use_module(library(scasp/options)).
:- use_module(library(scasp/messages)).
:- use_module(diff).
%:- include('clauses_solve.pl').

:- initialization(main, main).

test_scasp :-
    main([]).

qtest_scasp :-
    findall(File, quick_test_file(_, File), Files),
    main(Files).

quick_test_file(Test, File) :-
    (   atom(Test)
    ->  true
    ;   quick_test(Test)
    ),
    absolute_file_name(scasp(test/programs/Test), File,
                       [ access(read),
                         extensions([pl])
                       ]).

quick_test(pq).
quick_test(forall_arity).
quick_test(vars).
quick_test(classic_negation_inconstistent).
quick_test(birds).
quick_test(family).
quick_test(hamcycle).
quick_test(hamcycle_two).
quick_test(hanoi).


%!  main(+Argv)
%
%   Usage: swipl test_scasp.pl [option ...] [dir ...] [file ...]
%
%   Options:
%
%     |----------------|-------------------------------------|
%     | -q             | Only run the _quick_ tests          |
%     | --timeout=Secs | Run tests with timeout (default 60) |
%     | --save         | Save result if no .pass file exists |
%     | --overwrite    | Overwrite .pass after we passed     |
%     | --pass         | Overwrite .pass after we failed     |
%     | --cov[=Dir]    | Dump coverage data in Dir (`cov`)   |
%     | --cov-by-test  | Get coverage informatuion by test   |
%     | --target=File  | Coverage report for File            |
%
%   Default runs tests from `../test`

main(Argv) :-
    set_prolog_flag(encoding, utf8),
    argv_options(Argv, Positional, Options),
    test_files(Positional, Files, Options),
    scasp_set_options(Options),
    (   option(cov(Dir), Options)
    ->  show_coverage(run_tests(Files, Options),
                      [ dir(Dir) ])
    ;   run_tests(Files, Options),
        (   option(cov_by_test(true), Options)
        ->  covering_clauses(Options)
        ;   true
        )
    ).

opt_type(q,           quick,       boolean).
opt_type(timeout,     timeout,     number).
opt_type(save,        save,        boolean).
opt_type(overwrite,   overwrite,   boolean).
opt_type(pass,        pass,        boolean).
opt_type(cov,         cov,         file).
opt_type(cov_by_test, cov_by_test, boolean).
opt_type(Flag, Option, Type) :-
    scasp_opt_type(Flag, Option, Type).

opt_help(quick,       "Only run fast tests").
opt_help(timeout,     "Timeout per test in seconds").
opt_help(save,        "Save pass data if not yet present").
opt_help(overwrite,   "Save pass data if test passed").
opt_help(pass,        "Save pass data if test failed").
opt_help(cov,         "Write coverage data").
opt_help(cov_by_test, "Analyse coverage by test and compare").
opt_help(Option, Help) :-
    scasp_opt_help(Option, Help).

opt_meta(cov,     'DIRECTORY').
opt_meta(timeout, 'SECONDS').
opt_meta(Option, Meta) :-
    scasp_opt_meta(Option, Meta).

run_tests(Files, Options) :-
    run_tests(Files, Failed, Options),
    (   Failed == 0
    ->  format(user_error, 'All tests passed!~n', [])
    ;   format(user_error, '~D tests failed~n', [Failed]),
        (   current_prolog_flag(break_level, _)
        ->  fail
        ;   halt(1)
        )
    ).

run_tests(Files, Failed, Options) :-
    run_tests(Files, 0, Failed, Options).

run_tests([], Failed, Failed, _).
run_tests([H|T], Failed0, Failed, Options) :-
    (   run_test(H, Options)
    ->  run_tests(T, Failed0, Failed, Options)
    ;   Failed1 is Failed0+1,
        run_tests(T, Failed1, Failed, Options)
    ).

%!  run_test(+File, +Options) is semidet.
%
%   Compute all stacks and models for File.  Options:
%
%     - save(true)
%       Write new `.pass` file if there is none.
%     - overwrite(true)
%       Save the .pass file even if the test passed.
%     - show_diff(true)
%       Use `meld` to show the difference between the stacks if the
%       test failed.

run_test(File, Options) :-
    file_base_name(File, Base),
    format("~w ~`.t ~45|", [Base]),
    flush_output,
    option(timeout(Time), Options, 60),
    statistics(runtime, _),
    catch(call_with_time_limit(
              Time,
              scasp_test(File, Stacks-Models, Options)),
          Error, true),
    statistics(runtime, [_,Used]),
    Result = Stacks-Models,
    pass_data(File, PassFile, PassResult),
    (   PassResult = PassStacks-PassModels
    ->  true
    ;   PassStacks = PassResult         % old format
    ),
    (   nonvar(Error)
    ->  message_to_string(Error, Msg),
        format("ERROR: ~s ~|~t~d ms~8+\n", [Msg,Used]),
        fail
    ;   var(PassStacks)
    ->  length(Models, ModelCount),
        format("~D models ~|~t~d ms~8+\n", [ModelCount,Used]),
        (   option(save(true), Options)
        ->  save_test_data(PassFile, Result)
        ;   true
        )
    ;   PassStacks =@= Stacks
    ->  format("passed ~|~t~d ms~8+\n", [Used]),
        (   option(overwrite(true), Options)
        ->  save_test_data(PassFile, Result)
        ;   true
        )
    ;   PassModels =@= Models
    ->  format("different stacks, same models ~|~t~d ms~8+\n", [Used]),
        (   option(show_diff(true), Options)
        ->  diff_terms(PassStacks, Stacks)
        ;   option(pass(true), Options)
        ->  save_test_data(PassFile, Result)
        ;   true
        )
    ;   canonical_models(PassModels, CannonicalPassModels),
        canonical_models(Models, CannonicalModels),
        CannonicalPassModels =@= CannonicalModels
    ->  format("different stacks, same models (different order) ~|~t~d ms~8+\n",
               [Used]),
        (   option(show_diff(true), Options)
        ->  diff_terms(PassStacks, Stacks)
        ;   option(pass(true), Options)
        ->  save_test_data(PassFile, Result)
        ;   true
        )
    ;   format("FAILED ~|~t~d ms~8+\n", [Used]),
        (   option(pass(true), Options)
        ->  save_test_data(PassFile, Result)
        ;   option(show_diff(true), Options)
        ->  diff_terms(PassStacks, Stacks)
        ;   option(show_diff(models), Options)
        ->  canonical_models(PassModels, CannonicalPassModels),
            canonical_models(Models, CannonicalModels),
            diff_terms(CannonicalPassModels, CannonicalModels)
        ),
        fail
    ).

canonical_models(Models, CannModels) :-
    maplist(canonical_model, Models, Models1),
    sort(Models1, CannModels).

%!  pass_data(+TestFile, -PassFile, -PassData) is det.

pass_data(File, PassFile, PassData) :-
    file_name_extension(Base, _, File),
    file_name_extension(Base, pass, PassFile),
    (   exists_file(PassFile)
    ->  setup_call_cleanup(
            open(PassFile, read, In),
            read_term(In, PassData,
                      [ module(scasp_ops)
                      ]),
            close(In))
    ;   true
    ).

save_test_data(Into, Result) :-
    setup_call_cleanup(
        open(Into, write, Out),
        write_term(Out, Result,
                   [ module(scasp_ops),
                     quoted(true),
                     fullstop(true),
                     nl(true)
                   ]),
        close(Out)).

%!  test_files(+Argv, -Files, +Options) is det.

test_files([], Files, Options) :-
    !,
    (   option(quick(true), Options)
    ->  findall(File, quick_test_file(_, File), Files)
    ;   absolute_file_name(scasp(test/programs), Dir,
                           [ file_type(directory),
                             access(read)
                           ]),
        test_files([Dir], Files, Options)
    ).
test_files(Spec, Files, _Options) :-
    phrase(test_files_(Spec), Files).

test_files_([]) -->
    [].
test_files_([Dir|T]) -->
    { exists_directory(Dir) },
    !,
    findall(File, dir_test_file(Dir,File)),
    test_files_(T).
test_files_([File|T]) -->
    { exists_file(File) },
    !,
    [File],
    test_files_(T).
test_files_([H|T]) -->
    { print_message(warning, error(existence_error(file, H),_)) },
    test_files_(T).

dir_test_file(Dir, File) :-
    atom_concat(Dir, '/*.pl', Pattern),
    expand_file_name(Pattern, Files),
    member(File, Files).


%!  scasp_test(+File, -StackModelPairs, +Options) is det.
%
%   Test a single file

:- dynamic
    scasp_current_test/1.

scasp_test(File, Result, Options) :-
    option(cov_by_test(true), Options),
    !,
    collect_coverage(scasp_test(File, Result), File).
scasp_test(File, Result, _Options) :-
    scasp_test(File, Result).

scasp_test(File, Trees-Models) :-
    scasp_load(File, [unknown(fail)]),
    scasp_query(Query, Bindings, []),
    findall(Pair, solve(Query, Bindings, Pair), Pairs),
    pairs_keys_values(Pairs, Trees, Models).

solve(Query, Bindings, Tree-Model) :-
    solve(Query, [], StackOut, ModelOut),
    justification_tree(StackOut, Tree, []),
    canonical_model(ModelOut, Model),
    All = t(Bindings, Model, Tree),
    ovar_set_bindings(Bindings),
    ovar_analyze_term(All),
    inline_constraints(All, []).

		 /*******************************
		 *        COVERAGE BY FILE	*
		 *******************************/

:- meta_predicate
    collect_coverage(0, +).

collect_coverage(Goal, Test) :-
    setup_call_cleanup(
        asserta(scasp_current_test(Test), Ref),
        show_coverage(Goal, []),
        erase(Ref)).

:- multifile
    prolog_cover:report_hook/2.

prolog_cover:report_hook(Succeeded, Failed) :-
    scasp_current_test(Test),
    Module = scasp_solve,
    module_property(Module, file(Target)),
    convlist(tag_clause(Module, Target, +), Succeeded, STagged),
    convlist(tag_clause(Module, Target, -), Failed,    FTagged),
    append(STagged, FTagged, Tagged),
    sort(1, =<, Tagged, Which),       % Sort by line
    length(Which, N),
    format("\nFile ~w covers ~d clauses\n", [Test, N]),
    format("~n~`=t~78|~n", []),
    assertz(covers(Test, N, Which)).

tag_clause(Module, File, Symbol, Clause, cov(Line, Symbol, PI)) :-
    clause_property(Clause, file(File)),
    clause_property(Clause, line_count(Line)),
    clause_property(Clause, predicate(Module:PI)).

covering_clauses(Options) :-
    minimal_set_of_files(CoveredClauses, MinimalSetFiles),
    retractall(covers(_,_,_)),
    sep_line,
    format("Minimal Set of Files to obtain this coverage\n"),
    files_list(MinimalSetFiles, Files),
    sep_line,
    format("Running tests on this lot\n"),
    run_tests(Files, Options),
    sep_line,
    format("List of Clauses \nClause ~`.t State~72|~n", []),
    covered_clauses(CoveredClauses),
    format("\nEnd of the report\n", []).

sep_line :-
    format("~n~`=t~78|~n", []).

files_list([], []).
files_list([(N,File)|Rest], [File|RRest]) :-
    format("~d ~46t ~w~72|~n", [N,File]),
    files_list(Rest, RRest).

covered_clauses(CoveredClauses) :-
    findall(CIF, clause_in_module(scasp_solve, CIF), CIFs),
    sort(1, =<, CIFs, OCIFs),
    covered_clauses(OCIFs, CoveredClauses).

clause_in_module(Module, cif(Line, PI)) :-
    module_property(Module, file(File)),
    prolog_cover:clause_source(Clause, File, Line),
    clause_property(Clause, predicate(Module:PI)),
    \+ ( PI = (Name/_Arity),
         sub_atom(Name, 0, _, _, $)
       ).

covered_clauses([], _).
covered_clauses([cif(L, P)|RestC], Covered) :-
    (   memberchk(cov(L,+,P), Covered)
    ->  Message = 'COVERED'
    ;   memberchk(cov(L,-,P), Covered)
    ->  Message = 'NEG COVERED'
    ;   Message = 'NO'
    ),
    format("~t~d~4| ~q ~46t ~w~72|~n", [L, P, Message]),
    covered_clauses(RestC, Covered).

minimal_set_of_files(SetOfClauses, Minimal) :-
    findall((N,File,Which), covers(File, N, Which), Covering),
    sort(0, @>, Covering, Ordered),
    Ordered = [(N0, F0, S0)|RestF],
    grow_minimal_set(RestF, S0, [(N0,F0)], SClausesCovered, Minimal),
    list_to_set(SClausesCovered, SetOfClauses).

grow_minimal_set([], S, F, S, F).
grow_minimal_set([(N1,F1,S1)|RestF], InClauses, InFiles, OutClauses, OutFiles) :-
    (   subset(S1, InClauses)
    ->  NextClauses = InClauses, NextFiles = InFiles
    ;   append(InClauses, S1, NextClauses), NextFiles = [(N1,F1)|InFiles]
    ),
    grow_minimal_set(RestF, NextClauses, NextFiles, OutClauses, OutFiles).

