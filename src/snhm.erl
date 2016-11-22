%%%!------------------------------------------------------------------
%%% snhm -- 
%%%
%%% @Copyright:
%%% @Creator:  
%%% @Date Created: 2016-11-22
%%% @Description:  
%%%-------------------------------------------------------------------
-module(snhm).

-rcs('$Id$').
-behaviour(gen_server).

%%--------------------------------------------------------------------
%% API
%%--------------------------------------------------------------------
-export([start_link/0]).
-export([stop/0]).

%% For debugging:
-export([dump/0]).
-export([crash/0]).

%%--------------------------------------------------------------------
%% Internal exports
%%--------------------------------------------------------------------
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).
-export([terminate/2, code_change/3]).

%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% Definitions
%%--------------------------------------------------------------------
-define(SERVER, ?MODULE).
-define(TIMEOUT, infinity). %% milliseconds | infinity

%%--------------------------------------------------------------------
%% Records
%%--------------------------------------------------------------------

-record(state, {}).

%%====================================================================
%% API
%%====================================================================

%%!-------------------------------------------------------------------
%% start_link -- Start the server.
%%
%% start_link() -> {ok, Pid} | ignore | {error, Reason}
%%   Reason = {already_started, Pid} | term()
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%!-------------------------------------------------------------------
%% stop -- Stop the server.
%%
%% stop() -> ok
%%--------------------------------------------------------------------
stop() ->
    gen_server:call(?SERVER, stop, ?TIMEOUT).

%%!-------------------------------------------------------------------
%% dump -- Dump the server's internal state (for debugging purposes).
%%
%% dump() -> state()
%%--------------------------------------------------------------------
dump() ->
    gen_server:call(?SERVER, dump, ?TIMEOUT).

%%!-------------------------------------------------------------------
%% crash -- Crash the server (for debugging purposes).
%%
%% crash() -> exit()
%%--------------------------------------------------------------------
crash() ->
    gen_server:call(?SERVER, crash, ?TIMEOUT).

%%====================================================================
%% Server functions
%%====================================================================

%%!-------------------------------------------------------------------
%% init -- Initialize the server.
%%
%% init(ArgList) -> Return
%%   Return = {ok, State}          |
%%            {ok, State, Timeout} |
%%            ignore               |
%%            {stop, Reason}
%%--------------------------------------------------------------------
init([]) ->
    %%Initialize ETS table for clients storage
    ets:new(clients,[named_table,set]),
    {ok, #state{}}.

%%!-------------------------------------------------------------------
%% handle_call -- Handle call messages.
%%
%% handle_call(Request, From, State) -> Return
%%   From = {pid(), Tag}
%%   Return = {reply, Reply, State}          |
%%            {reply, Reply, State, Timeout} |
%%            {noreply, State}               |
%%            {noreply, State, Timeout}      |
%%            {stop, Reason, Reply, State}   | %(terminate/2 is called)
%%            {stop, Reason, State}            %(terminate/2 is called)
%%--------------------------------------------------------------------

%%Add particular client IP whose health needs to be monitored
handle_call({add,IP}, From, State) ->
    Reply = case ets:lookup(clients,{IP,From}) of
		[] ->
		    ets:insert(clients,{{IP,From},erlang:timestamp()});
		_ ->
		    ok
	    end,		
    {reply, Reply, State};
%%Remove particular client IP to remove monitoring
handle_call({remove,IP}, From, State) ->
    Reply = ets:delete(clients,{IP,From}),		
    {reply, Reply, State};

%%Update ping status on all the client IPs
handle_call({icmp_ping,all}, _From, State) ->
    %%Ping the client and update database,Reply should be 
    %%ping response
    Reply = case ets:foldl(fun(E,AccIn) -> 
				   io:format("Pinging and updating response to database~n")
			   end,[],clients) of
		[] ->
		    io:format("No responses or probably no clients~n"),
		    ok;
		Responses ->
		    io:format("Updated the responses in TS DB:~n~p~n",[Responses]),
		    Responses
	    end,
    {reply, Reply, State};
%%update the ping status
handle_call({icmp_ping,IP}, From, State) ->
    %%if two different clients giving the same IP, 
    %%Table is updated with latest "From" reference
    ets:insert(clients,{{IP,From},erlang:timestamp()}),
    %%Ping the client and update database,Reply should be 
    %%ping response
    Reply = ok,
    {reply, Reply, State};


handle_call(stop, _From, State) ->
    {stop, normal, ok, State};
handle_call(dump, _From, State) ->
    io:format("~p:~p: State=~n  ~p~n", [?MODULE, self(), State]),
    {reply, State, State};
handle_call(crash, From, _State) ->
    erlang:error({deliberately_crashed_from,From});
handle_call(UnknownRequest, _From, State) ->
    {reply, {error, {bad_request, UnknownRequest}}, State}.

%%!-------------------------------------------------------------------
%% handle_cast -- Handle cast messages.
%%
%% handle_cast(Msg, State) -> Return
%%   Return = {noreply, State}          |
%%            {noreply, State, Timeout} |
%%            {stop, Reason, State}            %(terminate/2 is called)
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%!-------------------------------------------------------------------
%% handle_info -- Handle all non call/cast messages.
%%
%% handle_info(Info, State) -> Return
%%   Return = {noreply, State}          |
%%            {noreply, State, Timeout} |
%%            {stop, Reason, State}            %(terminate/2 is called)
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%!-------------------------------------------------------------------
%% terminate -- Shutdown the server.
%%
%% terminate(Reason, State) -> void()
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%!-------------------------------------------------------------------
%% code_change -- Convert process state when code is changed.
%%
%% code_change(OldVsn, State, Extra) -> {ok, NewState}
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------
