pr_rule(penguin(sam),[]).
pr_rule(wounded_bird(john),[]).
pr_rule(bird(tweety),[]).
pr_rule(bird(X),[penguin(X)]).
pr_rule(bird(X),[wounded_bird(X)]).
pr_rule(ab(X),[penguin(X)]).
pr_rule(ab(X),[wounded_bird(X)]).
pr_rule(flies(X),[bird(X),not(ab(X))]).
pr_rule(not(o_flies1(X)),[not(bird(X))]).
pr_rule(not(o_flies1(X)),[bird(X),ab(X)]).
pr_rule(not(flies(_X0)),[not(o_flies1(_X0))]).
pr_rule(not(o_ab1(X)),[not(penguin(X))]).
pr_rule(not(o_ab2(X)),[not(wounded_bird(X))]).
pr_rule(not(ab(_X0)),[not(o_ab1(_X0)),not(o_ab2(_X0))]).
pr_rule(not(o_bird1(_X0)),[_X0 .\=. tweety]).
pr_rule(not(o_bird2(X)),[not(penguin(X))]).
pr_rule(not(o_bird3(X)),[not(wounded_bird(X))]).
pr_rule(not(bird(_X0)),[not(o_bird1(_X0)),not(o_bird2(_X0)),not(o_bird3(_X0))]).
pr_rule(not(o_wounded_bird1(_X0)),[_X0 .\=. john]).
pr_rule(not(wounded_bird(_X0)),[not(o_wounded_bird1(_X0))]).
pr_rule(not(o_penguin1(_X0)),[_X0 .\=. sam]).
pr_rule(not(penguin(_X0)),[not(o_penguin1(_X0))]).
pr_rule(not(o_false),[]).
pr_rule(not(o_false),[]).
pr_rule(o_nmr_check,[]).
pr_rule(add_to_query,[o_nmr_check]).
