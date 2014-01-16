-module(list_deps).

-compile(export_all).

main([]) ->
    main(["./"]);
main([Help]) when Help =:= "-h";
                  Help =:= "-?";
                  Help =:= "--help" ->
    io:format("Usage: list_deps <dir>~n", []),
    erlang:halt(0);
main([Dir]) ->
    Deps = expand_deps(Dir),
    io:format("~P.~n", [Deps, 10000]),
    erlang:halt(0).

read_deps(File) ->
    try
        {ok, Terms} = file:consult(File),
        proplists:get_value(deps, Terms, [])
    catch
        error:{badmatch, _} ->
            []
    end.

expand_deps(Dir) ->
    FoundDeps = sets:new(),
    DepInfo = [],
    expand_deps(Dir, ["rebar.config"], FoundDeps, DepInfo).

expand_deps(_RootDir, [], _FoundDeps, DepInfo) ->
    {deps, lists:keysort(1, DepInfo)};
expand_deps(RootDir, [CurFile | Files], FoundDeps, DepInfo) ->
    CurDeps = read_deps(CurFile),
    NewDeps = filter_deps(CurDeps, FoundDeps),
    NewDepNames = [ dep_name(D) || D <- NewDeps ],
    NewFoundDeps = sets:union(sets:from_list(NewDepNames),
                              FoundDeps),
    NewDepInfo = NewDeps ++ DepInfo,
    NewFiles = [ dep_file(RootDir, Name) || Name <- NewDepNames ],
    expand_deps(RootDir, Files ++ NewFiles, NewFoundDeps, NewDepInfo).

dep_file(Dir, DepName) ->
    filename:join([Dir, "deps", DepName, "rebar.config"]).

filter_deps(NewDeps, FoundDeps) ->
    lists:filter(fun (Dep) ->
                         Name = dep_name(Dep),
                         not sets:is_element(Name, FoundDeps)
                 end,
                 NewDeps).

dep_name(Dep) when is_tuple(Dep) ->
    element(1, Dep).
