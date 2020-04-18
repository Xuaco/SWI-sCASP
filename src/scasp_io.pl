:- module(scasp_io, [
    load_program/1,
    write_program/0,
    process_query/2,
    ask_for_more_models/0,
    allways_ask_for_more_models/0,
    init_counter/0,
    increase_counter/0,
%    print_output/1,
    print_all_output/1,
    print_model/1,
%    print_term/3,
    pretty_term/4,
    print_unifier/2,
    print_check_calls_calling/2,
    if_user_option/2,
    set/2,
    parse_args/3,
    current_option/2,
    counter/2,
    set_options/1,
    answer_counter/1
    ]).


%% ------------------------------------------------------------- %%
:- use_package(assertions).
:- doc(title, "Module for input / output predicates").
:- doc(author, "Joaquin Arias").
:- doc(filetype, module).

:- doc(module, "

This module contains the code used to load, parser, translate and
print the program and results of the evaluation. It uses the
implementation of s(ASP) by @em{Marple} ported to CIAO by @em{Joaquin
Arias} in the folder @file{./src/sasp/}.

").

%% ------------------------------------------------------------- %%

:- use_module('./sasp/output').
:- reexport('./sasp/output', [
    pr_rule/2,
    pr_query/1,
    pr_user_predicate/1,
    pr_table_predicate/1,
    pr_show_predicate/1
                            ]).
:- use_module('./sasp/main').

%% ------------------------------------------------------------- %%


:- pred load_program(Files) : list(Files) #"Call s(aso) to generate
    and assert the translation of the progam (with dual and
    nmr_check)".

:- dynamic loaded_file/1.
load_program([]) :-
    display('ERROR: No imput file specified!'),nl,nl,
    help. %% halt.
load_program(X) :-
    retractall(loaded_file(_)),
    (
        list(X) ->
        Files = X
    ;
        Files = [X]
    ),
    main(['-g'| Files]),
    assert(loaded_file(Files)).

:- pred write_program/0 #"Call c(asp) to print the source code of the
translation of the programs already loaded by @pred{load_program/1}".

write_program :-
    loaded_file(Files),
    main(['-d0'|Files]).

:- dynamic cont/0.

:- pred process_query(Q, Query) #"Initialize internal flags to allows
the generation of multiples models in the interaction and top-level
mode (even when the query is ground). Returns in @var{Query} a list
with the sub_goals in @var{Q} and @em{nmr_check} with run the
nmr_check".

process_query(Q,Query) :-
    revar(Q,A),
    (
        list(A) -> As = A ; As = [A]
    ),
    (
        As = [not(_)|_] ->
        Bs = [true|As]
    ;
        Bs = As
    ),
    retractall(cont),
    (
        ground(Bs) -> assert(cont) ; true
    ),
    ( current_option(no_nmr,on) ->
        append(Bs, [true], Query)
    ;
        append(Bs, [add_to_query], Query)
    ).

:- pred ask_for_more_models/0 #"Ask if the user want to generate more
models (interactive and top-level mode)".

ask_for_more_models :-
    (
        cont, print('next ? '), get_char(R),true, R \= '\n' ->
        get_char(_),
        statistics(runtime,_),
        fail
    ;
        true
    ).

:- pred ask_for_more_models/0 #"Ask if the user want to generate more
models (execution from console)".

allways_ask_for_more_models :-
    (
        print(' ? '), get_char(R),true, R \= '\n' ->
        get_char(_),
        nl,
        statistics(runtime,_),
        fail
    ;
        true
    ).

:- pred init_counter/0 #"Reset the value of answer_counter to 0".

:- dynamic answer_counter/1.
init_counter :-
    retractall(answer_counter(_)),
    assert(answer_counter(0)).

:- pred increase_counter/0 #"Add 1 to the current value of
answer_counter".

increase_counter :-
    answer_counter(N),
    N1 is N + 1,
    retractall(answer_counter(N)),
    assert(answer_counter(N1)).

%% :- pred print_output(StackOut) #"Print the justification tree using
%% @var{StackOut}, the final call stack".

%% Print output predicates to presaent the results of the query
%% print_output(StackOut) :-
%%     print_stack([],_,StackOut), nl,
%%     true.

:- pred print_all_output(StackOut) #"Print the justification
tree using @var{StackOut}, the final call stack".

%% Print output predicates to presaent the results of the query
print_all_output(StackOut) :-
    print_all_stack(StackOut), nl,
    true.

:- pred print_model(Model) #"Print the partial model of the program
using @var{Model}.".

%% The model is obtained from the model.
% TODO: use the StackOut instead of the model.
print_model(Model) :-
    nl,
    select_printable_literals(Model,Printable),
    print_model_(Printable), nl.

select_printable_literals([],[]) :- !.
select_printable_literals([X|Xs],NSs) :-
    select_printable_literals(X,S), !,
    select_printable_literals(Xs,Ss),
    append(S,Ss,NSs).
select_printable_literals(X,[X]) :-
    printable_literal(X), !.
select_printable_literals(_,[]).


print_model_([]).
print_model_([Last]) :- 
    print(Last).
print_model_([First,Second|Rest]) :-
    print(First),
    print(' ,  '),
    print_model_([Second|Rest]).

printable_literal(not(X)) :- printable_literal(X).
printable_literal(X) :-
    X \= 'add_to_query',
    X \= 'o_nmr_check',
    X \= chs(_),
    (
        pr_show_predicate(_) ->
        pr_show_predicate(X)
    ;
        X \= proved(_)
    ).

%% print_j(Justification,I) :-
%%     print_model(Justification),
%%     nl,
%%     print_j_(Justification,I).
%% print_j_([],_).
%% print_j_([A,[]],I):- !,
%%     tab(I), print(A), print('.'), nl.
%% print_j_([A,[]|B],I):- !,
%%     tab(I), print(A), print(','), nl,
%%     print_j_(B,I).
%% print_j_([A,ProofA|B],I):-
%%     tab(I), print(A), print(' :-'), nl,
%%     I1 is I + 4, print_j_(ProofA,I1),
%%     print_j_(B,I).

%% The stack is generated adding the last calls in the head (to avoid
%% the use of append/3). To print the stack, it is reversed.

%% NOTE that a model could be generated during the search with some
%% calls in the stack which are not present in the model (e.g. the
%% model of path(1,4) for the path/2 program - more details in the
%% file README)

%% print_stack(Stack) :-
%%     reverse(Stack, RStack),
%%     nl,
%%     nl,nl,
%%     %    print(RStack),nl.
%%     print_s(RStack).

print_all_stack(Stack) :-
%    reverse(Stack, RStack),
    nl,
    print_s(Stack).




%% Initial interpreters...
query2([]).
query2([X|Xs]) :-
    query2(Xs),
    query2(X).
query2(X) :-
    pr_rule(X, Body),
    query2(Body).


%:- table query3/3.
query3([X|Xs], I, O) :-
    format('Calling ~w \t with stack = ~w', [X, I]), nl,
    query3(X,  [X|I], O1),
    query3(Xs, O1,    O).
query3([], I, I) :- !.
query3(X,  I, O) :-
    pr_rule(X, Body),
    query3(Body, I, O).


:- pred print_unifier(Vars,PVars) #" Predicate to print @var{PVars} =
@var{Vars} the binding of the variables in the query".

print_unifier([],[]).
print_unifier([Binding|Bs],[PV|PVars]) :-
    ( PV == Binding ->
        true
    ;
        ( Binding =.. [_,PB,{PConst}], PV = PB ->
            format(" \n~w",[PConst])
        ;
            format(" \n~w = ~w",[PV,Binding])
        )
    ),
    print_unifier(Bs,PVars).

print_constraints('│',_,Const) :-
    format("~w",[Const]).
print_constraints('∉',PB,(Const)) :- !,
    print_constraints_not(PB,Const).
print_constraints('∉',PB,(Const,Cs)) :-
    print_constraints_not(PB,Const),
    format(", ",[]),
    print_constraints('∉',PB,Cs).
print_constraints_not(PB,Const) :-
    format("~w \= ~w",[PB,Const]).


:- pred print_check_calls_calling(Goal, StackIn) #"Auxiliar predicate
to print @var{StackIn} the current stack and @var{Goal}. This
predicate is executed when the flag @var{check_calls} is
@em{on}. NOTE: use check_calls/0 to activate the flag".

print_check_calls_calling(Goal,I) :-
    reverse([('¿'+Goal+'?')|I],RI),
    format('\n---------------------Calling ~p-------------',[Goal]),
    print_s(RI).

print_s([A|Stack]) :-
    nl,tab(0),print(A),
    print_s_(Stack,4,0).

print_s_([],_,_) :-
    display('.'), nl.
print_s_([[]|As],I,I0) :- !,
    I1 is I - 4,
    print_s_(As,I1,I0).
print_s_([A|As],I,I0) :- !,
    (
        I0 > I ->
        print('.')
    ;
        I0 < I ->
        print(' :-')
    ;
        print(',')
    ),
    nl,tab(I),print(A),
    I1 is I + 4,
    print_s_(As,I1,I).

  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Print pretty term
%% (Also variables with attributes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% print_term(D0,D1,A) :-
%%     pretty_term(D0,D1,A,P),
%%     print(P).

%% :- data next_letra/1.
%% %% init_mydict :-
%% %%     retractall(next_letra(_)),
%% %%     assert(next_letra(1)).

%% next_letra(L1) :-
%%     retract(next_letra(L0)),!,
%%     L1 is L0 + 1,
%%     assert(next_letra(L1)).
%% next_letra(0).

lookup_mydict(D0,D1,A,L) :-
    ( lookup_mydict_(D0,A,L) ->
        D1 = D0
    ;
        length(D0,L),
        D1 = [(A,L)|D0]
    ).

lookup_mydict_([],_,_) :- !, fail.
lookup_mydict_([(V,L)|_],A,L) :- V == A, !.
lookup_mydict_([_|Rs],A,L) :- lookup_mydict_(Rs,A,L).

:- use_module(engine(attributes)).
pretty_term(D0,D1,A,PA) :-
    var(A), !,
    lookup_mydict(D0,D1,A,N),
    Letter is N mod 26 + 0'A,
    atom_codes(L,[Letter]),
    (   N>=26 ->
        Rest is N//26,
        atom_number(AtomRest,Rest),
        atom_concat(L,AtomRest,PVar)
    ;   PVar=L
    ),
    ( get_attribute(A,Att) ->
        pretty_portray_attribute(Att,A,PVar,PA)
    ;
        PA = PVar
    ).
pretty_term(D0,D0,[],[]) :- !.
pretty_term(D0,D2,[A|As],[PA|PAs]) :- !,
    pretty_term(D0,D1,A,PA),
    pretty_term(D1,D2,As,PAs).
pretty_term(D0,D0,rat(A,B),A/B) :- !.
pretty_term(D0,D1,Functor,PF) :-
    Functor =..[Name|Args], !,
    pretty_term(D0,D1,Args,PArgs),
    (   pretty_clp(Name,PName) ->
        simple_operands(PArgs,SArgs),
        PF =.. [PName|SArgs]
    ;   pretty_clp(_,Name) ->
        simple_operands(PArgs,SArgs),
        PF =.. [Name|SArgs]
    ;
        PF =.. [Name|PArgs]
    ).
pretty_term(D0,D0,A,'?'(A)).

simple_operands([A,B],[SA,SB]) :-
    simple_operand(A,SA),
    simple_operand(B,SB).
simple_operand(Operand,Var) :-
    Operand =.. ['│', Var, _], !.
%% simple_operand(Operand,SOperand) :-
%%     struct(Operand),
%%     Operand =.. [Op|Args], !,
%%     simple_operands(Args,SArgs),
%%     SOperand =.. [Op|SArgs].
simple_operand(A,A).
 

:- use_module(library(clpq/clpq_dump), [clpqr_dump_constraints/3]).
pretty_portray_attribute(Att,A,PVar,PA) :-
    pretty_portray_attribute_(Att,A,PVar,PA), !.
pretty_portray_attribute(_Att,_,PVar,PVar).

%:- use_module(library(formulae)).
:- op(700, xfx, ['│'
                ]).

pretty_portray_attribute_(att(_,false,att(clp_disequality_rt,neg(List),_)),_,PVar,PA) :-
    (  List == [] ->
        PA=PVar
    ;
        pretty_disequality(PVar,List,Const),
        PA =.. ['│', PVar, {Const}]
    ).
pretty_portray_attribute_(_,A,PVar,PA) :-
    clpqr_dump_constraints(A, PVar, Constraints),
    (  Constraints == [] ->
        PA=PVar
    ;
        sort(Constraints,Sort),
        reverse(Sort,RConstraints),
        pretty_constraints(RConstraints,Const),
        PA =.. ['│', PVar, {Const}]
    ).

pretty_disequality(PVar,[A],(PVar \= A)) :- !.
pretty_disequality(PVar,[A|As],(PVar \= A, Cs)) :-
    pretty_disequality(PVar,As,Cs).
    
pretty_constraints([A],(C)) :- !,
    pretty_constraints_(A,C).
pretty_constraints([A|As],(C,Cs)) :-
    pretty_constraints_(A,C),
    pretty_constraints(As,Cs).
pretty_constraints_(A,C) :-
    A =.. [Op,X,Y],
    pretty_rat(X,PX),
    pretty_rat(Y,PY),
    ( pretty_clp(Op,P_Op) ->
        C =.. [P_Op,PX,PY]
    ;
        format("WARNING: clp operator ~w not defined\n",[Op]),
        C =.. [Op,PX,PY]
    ).    
pretty_constraints_(A,A).
pretty_rat(rat(A,B),A/B) :- !.
pretty_rat(A,A).

pretty_clp(N,PN) :- pretty_clp_(N,PN), !.

:- op(700, xfx, ['#=' ,
                 '#<>',
                 '#<' ,
                 '#>' ,
                 '#=<',
                 '#>='
                 ]).
pretty_clp_(.=.,  '#=' ).
pretty_clp_(.<>., '#<>').
pretty_clp_(.<.,  '#<' ).
pretty_clp_(.>.,  '#>' ).
pretty_clp_(.=<., '#=<').
pretty_clp_(.>=., '#>=').
pretty_clp_(\=, \=).
    
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic current_option/2, counter/2.

set_options(Options) :-
    set_default_options,
    set_user_options(Options).

set_default_options :-
    set(answers,-1),
    set(verbose,0).

set_user_options([]).
set_user_options([O | Os]) :-
    (
        set_user_option(O) ->
        set_user_options(Os)
    ;
        format('ERROR: The option ~w is not supported!\n\n',[O]),
        help,
        fail
    ).

set_user_option('-h') :- help.
set_user_option('-?') :- help.
set_user_option('--help') :- help.
set_user_option('-i') :- set(interactive, on).
set_user_option('--interactive') :- set(interactive, on).
set_user_option('-a').
set_user_option('--auto').
set_user_option(Option) :- atom_chars(Option,['-','s'|Ns]),number_chars(N,Ns),set(answers,N).
set_user_option(Option) :- atom_chars(Option,['-','n'|Ns]),number_chars(N,Ns),set(answers,N).
set_user_option('-v') :- set(check_calls, on).
set_user_option('--verbose') :- set(check_calls, on).
set_user_option('-w') :- set(warning, on).
set_user_option('--warning') :- set(warning, on).
set_user_option('-no') :- set(no_nmr, on).
set_user_option('--no_nmr') :- set(no_nmr, on).
set_user_option('-j') :- set(print_all, on), set(process_stack, on).
set_user_option('-j0') :- set(print_all, on), set(process_stack, on).
set_user_option('--justification') :- set(print_all, on), set(process_stack, on).
set_user_option('-d0') :- set(write_program, on).
set_user_option('--html') :- set(html, on), set(process_stack, on).
set_user_option('--server') :- set(html, on), set(server, on), set(process_stack, on).

:- pred if_user_option(Name, Call) : (ground(Name), callable(Call))
#"If the flag @var{Name} is on them the call @var{Call} is executed".

if_user_option(Name,Call) :-
    (
        current_option(Name,on) ->
        call(Call)
    ;
        true
    ).

:- pred set(Option, Value) #"Used to set-up the user options".

set(Option, Value) :-
    retractall(current_option(Option, _)),
    assert(current_option(Option,Value)).

help :-
    display('Usage: scasp [options] InputFile(s)\n\n'),
    display('s(CASP) computes stable models of ungrounded normal logic programs.\n'),
    display('Command-line switches are case-sensitive!\n\n'),
    display(' General Options:\n\n'),
    display('  -h, -?, --help        Print this help message and terminate.\n'),
    display('  -i, --interactive     Run in user / interactive mode.\n'),
    display('  -a, --auto            Run in automatic mode (no user interaction).\n'),
    display('  -sN, -nN              Compute N answer sets, where N >= 0. 0 for all.\n'),
    display('  -v, --verbose         Enable verbose progress messages.\n'),
    display('  -w, --warning         Enable warning messages (failing in variant loops).\n'),
    display('  -j, --justification   Print proof tree for each solution.\n'),
    display('  --html                Generate the proof tree in a file named InputFiles(s).html.\n'),
    display('  --server              Generate the proof tree in the file named justification.html.\n'),
    display('  -d0                   Print the program translated (with duals and nmr_check).\n'),
    display('\n'),
    abort.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parse arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- pred parse_args(Args, Options, Sources) #"Select from the list of
arguments in @var{Args} which are the user-options, @var{Options} and
which are the program files, @var{Sources}".

parse_args([],[],[]).
parse_args([O | Args], [O | Os], Ss) :-
    atom_concat('-',_,O),!,
    parse_args(Args, Os, Ss).
parse_args([S | Args], Os, [S | Ss]) :-
    parse_args(Args, Os, Ss).



:- use_module('html/html_head').
:- use_module('html/jquery02').
:- use_module('html/jquery_tree').
:- use_module('html/html_tail').
:- pred print_html(Sources, Query, Model, StackOut) #"Generate a html
file with the model and the justification tree of the @var{Sources}
forq the @var{Query} using @var{Model} and @var{StackOut} resp.".

%% Print output predicates to presaent the results of the query
print_html(Sources,Query, Model, StackOut) :-
    write('\nBEGIN HTML JUSTIFICATION'),
    ( current_option(server,on) ->
        Name=justification
    ;
        create_file_name(Sources,Name)
    ),
    atom_concat(Name,'.html',File),
%    File = 'html/justification.html',
    open_output_file(Stream,File,Current),
    if(
        (
            load_html_head(Head),
            print(Head),
            print('<h3>Query</h3>'),nl,
            print_html_query(Query),nl,
            br,br,nl,
            print('<h3>Model</h3>'),nl,
            print_model(Model),nl,
            br,br,nl,
            print('<h3> Justification <button onclick="expand()">Expand All</button><button onclick="collapse()">Collapse All</button></h3>\n <ul class="tree">'),
            print_html_stack(StackOut),
            nl,print('</ul>'),nl,nl,
            load_jquery(Jquery),
            print(Jquery),nl,
            load_jquery_tree(Jquery_tree),
            print(Jquery_tree),nl,
            load_html_tail(Tail),
            print(Tail)
        ),true,true),
    close_output_file(Stream,Current),
    write(' and END\n'), 
    !.


create_file_name([Ss],F) :-
    name(Ss,StringS),
    create_file_name_(StringS,StringF),
    name(F,StringF).
create_file_name([A,B|Ss],Fs) :-
    create_file_name([A],F),
    create_file_name([B|Ss],Fm),
    atom_concat(F,'-',F1),
    atom_concat(F1,Fm,Fs).
create_file_name_([46|_],[]) :- !.
create_file_name_([],[]) :- !.
create_file_name_([L|Ls],[L|F2]) :-
    create_file_name_(Ls,F2).


:- use_module(library(terms_check)).
print_html_query([PQ,Bindings,PVars]) :-
        print('<b>\n  <font color=blue>?-</font> '),nl,
        print_body(PQ),
        nl,br,br,nl,
        print_html_unifier(Bindings,PVars),
        print(' ?'),
        br,nl,
        print('</b>').

print_html_unifier([],[]).
print_html_unifier([Binding|Bs],[PV|PVars]) :-
    ( PV == Binding ->
        true
    ;
        ( Binding =.. [_,PB,{PConst}], PV = PB ->
            format(" <br> \n~w",[PConst])
        ;
            format(" <br> \n~w = ~w",[PV,Binding])
        )
    ),
    print_html_unifier(Bs,PVars).


print_html_stack([A|StackOut]) :-
%    reverse(StackOut,[A|ReverseStack]),
    nl,tab(5),print('<li> '),
    nl,tab(5),print('  '),print_html_term(A),     
    print_html_stack_(StackOut,9,5).

print_html_stack_([],I,I0) :-
    display('.'),
    nl,tab(I0), print('</li> '),
    close_ul(I0,I).
print_html_stack_([[]|As],I,I0) :- !,
    I1 is I - 4,
    print_html_stack_(As,I1,I0).
print_html_stack_([A|As],I,I0) :- !,
    (
        I0 > I ->
            print('.'),
            nl,tab(I0), print('</li> '),
            close_ul(I0,I)
    ;
        I0 < I ->
            print(' :-'),
            nl,tab(I0), print('  <ul>')
    ;
        print(','),
        nl,tab(I0), print('</li>')
    ),
    nl,tab(I),print('<li> '),
    nl,tab(I),print('  '),print_html_term(A),     
    I1 is I + 4,
    print_html_stack_(As,I1,I).

print_html_term(Constraint) :-
    Constraint =.. [Op,A,B],
    pretty_clp(_,Op), !,
    format("~w ~w ~w",[A,Op,B]).
print_html_term(A) :- print(A).

close_ul(I,I) :- !.
close_ul(I0,I) :-
    I0 > I,
    I1 is I0 - 4,
    ( I1 > 2 ->
        nl,tab(I1), print('</ul> '),
        nl,tab(I1), print('</li> ')
    ;
        true
    ),
    close_ul(I1,I).


%% print_list([],_).
%% print_list([X|Xs],L) :-
%%     tabs(L),
%%     print('<li> '),
%%     print_item(X,L),
%%     print('</li>'),nl,
%%     print_list(Xs,L).

%! tab_html(+Level:int) is det
% Write Level spaces.
%
% @param Level The level to tabs to.
tab_html(N) :-
    N > 0,
    N1 is N - 1,
    write('&nbsp;'),
    !,
    tab_html(N1).
tab_html(0).

print_body([]) :- print('true.').
print_body([X]):-
    print(X),print('.').
print_body([X,Y|Xs]):-
    print(X),print(','),tab_html(2),nl,
    print_body([Y|Xs]).

open_output_file(Stream,File,Current) :-
    current_output(Current),
    open(File,append,_F),close(_F), %% if File does not exists open it
    open(File,write,Stream),
    set_output(Stream).
close_output_file(Stream,Current) :-
    set_output(Current),
    close(Stream).
    
br :- print('<br>').

