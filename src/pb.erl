%% Skeleton of protobufs compiler.  This is a work in progress, not yet ready for use.

-module(pb).
-export([compile/1, compile/2]).

-record(pb_state, {output, dirname, module, line=1, directives}).

compile(Filename) ->
    compile(Filename, []).
    
compile(Filename, Options) ->
    case parse(Filename) of
        {ok, Parse} ->
            Module = list_to_atom(filename:rootname(filename:basename(Filename))),
            %% XXX: Use {i, Dir} to specify include dirs, like compiler.
            Dirname = proplists:get_value(basedir, Options, filename:dirname(Filename)),
            OutputFilename = atom_to_list(Module) ++ ".erl",
            {ok, Output} = file:open(OutputFilename, [write]),
            write_file(#pb_state{module=Module, dirname=Dirname, output=Output, directives=Parse}),
            {ok, OutputFilename};
        {error, Error} ->
            {error, Error}
    end.

parse(Filename) ->
    {ok, Text} = file:read_file(Filename),
    Tokens = proto_scan:scan(binary_to_list(Text)),
    case proto_parse:parse(Tokens) of
        {ok, Parse} ->
            {ok, Parse};
        {error, {Line, Module, Err}} ->
            {error, {Line, Module:format_error(Err)}}
    end.
        
write_file(State0) ->
    State1 = output_prelude(State0),
    output_directives(State1, State1#pb_state.directives).

output_prelude(State0) ->
    Module = State0#pb_state.module,
    PackageAndModule =
        case proplists:get_value(package, State0#pb_state.directives) of
            undefined -> atom_to_list(Module);
            Package -> [Package, ".", atom_to_list(Module)]
        end,
        
    State1 = fwrite(State0, <<"-module(~s).\n">>, [PackageAndModule]).

output_directives(State0, Directives) ->
    lists:foldl(fun output_directive/2, State0, Directives).

output_directive({package, _}, State0) ->
    %% Package was already taken care of in the prelude.
    State0;
output_directive({option, OptionName, OptionValue}, State0) ->
    %% We don't implement any options yet.
    fwrite(State0, <<"%% option ~s ~p\n">>, [OptionName, OptionValue]);
output_directive({import, Filename}, State0) ->
    %% Parse the included file and output its directives.
    {ok, Parse} = parse(filename:join(State0#pb_state.dirname, Filename)),
    State1 = fwrite(State0, <<"%% import(~s)\n">>, [Filename]),
    output_directives(State1, Parse);
output_directive({enum, EnumName, Params}, State0) ->
    Values = [{K, V} || {enum_value, K, V, _} <- Params],
    {FirstK, FirstV} = hd(Values),
    State1 = fwrite(State0, <<"enum_~s(~p) -> ~p">>, [EnumName, FirstK, FirstV]),
    State2 = lists:foldl(fun ({K, V}, St) ->
        fwrite(State0, <<";\nenum_~s(~p) -> ~p">>, [EnumName, K, V])
    end, State1, tl(Values)),
    fwrite(State2, <<".\n\n">>, []);
output_directive({message, MessageName, Params}, State0) ->
    fwrite(State0, <<"make_~s(Params) ->\n    pb_message:encode(~p, ~p, Params).\n">>, [MessageName, MessageName, Params]);
output_directive({extend, ExtendName, Params}, State0) ->
    fwrite(State0, <<"%% extend ~s\n">>, [ExtendName]);
output_directive({service, ServiceName, Params}, State0) ->
    fwrite(State0, <<"%% service ~s\n">>, [ServiceName]).

fwrite(#pb_state{output=Output, line=Line} = State, Format, Args) ->
    NLines = count_nl(Format),
    io:fwrite(Output, Format, Args),
    State#pb_state{line=Line + NLines}.

count_nl(Binary) ->
    count_nl(Binary, 0).
    
count_nl(<<$\n,Rest/binary>>, Count) ->
    count_nl(Rest, Count + 1);
count_nl(<<"~n",Rest/binary>>, Count) ->
    count_nl(Rest, Count + 1);
count_nl(<<_,Rest/binary>>, Count) ->
    count_nl(Rest, Count);
count_nl(<<>>, Count) ->
    Count.
