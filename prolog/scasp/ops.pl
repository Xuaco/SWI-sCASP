:- module(scasp_ops,
          [ op(700, xfx, [.=., .\=.,.<>.,.<.,.=<.,.>.,.>=.]),
            op(700, xfx, [#= , #<>, #< , #> , #=<, #>= ]),
            op(700, xfx, [::]),
            op(700, xfx, ['| ']),
            op(700, xfx, [~>, <~]),
            op(900, fy,  [not]),
            op(700, xfx, ['\u2209']),

            scasp_push_operators/0,
            scasp_pop_operators/0
          ]).
:- use_module(library(apply)).
:- use_module(library(operators)).

scasp_push_operators :-
    prolog_load_context(module, Context),
    findall(op(Pri, Ass, Op), scasp_op(Pri, Ass, Op), Ops),
    push_operators(Context:Ops).
scasp_pop_operators :-
    pop_operators.

term_expansion(scasp_op(Pri, Ass, List), Ops) :-
    maplist(mkop(Pri, Ass), List, Ops).

mkop(Pri, Ass, Op, scasp_op(Pri, Ass, Op)).

scasp_op(700, xfx, [.=., .\=.,.<>.,.<.,.=<.,.>.,.>=.]).
scasp_op(700, xfx, [#= , #<>, #< , #> , #=<, #>= ]).
scasp_op(700, xfx, [::]).
scasp_op(700, xfx, ['| ']).
scasp_op(700, xfx, [~>, <~]).
scasp_op(900, fy,  [not]).
scasp_op(700, xfx, ['\u2209']).

% from input.pl
scasp_op(400, fx,  #).
scasp_op(300, xfx, ::).
scasp_op(350, fx,  [include, table, show, pred, compute, abducible]).
