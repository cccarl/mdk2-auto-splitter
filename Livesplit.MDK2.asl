state("mdk2Main") {
    bool loading  : 0x1D1224;
    int  level    : 0xBB724;
    int  sublevel : 0xBBA8C;
    int  music    : 0xBC364;
}

startup {
    settings.Add("game_time_set", true, "Ask if Game Time should be used when opening the game");
}

init {

    if (timer.CurrentTimingMethod == TimingMethod.RealTime && settings["game_time_set"]){
        var message = MessageBox.Show(
            "LiveSplit has a load remover for this game available when comparing against Game Time. Would you like to change the current timing method to Game Time instead of Real Time?", 
            "LiveSplit | MDK2 Load Remover", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

        if (message == DialogResult.Yes){
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
    
    vars.startActions = (EventHandler)((s, e) => {
        if (current.loading) {
			// to force the timer to start at 0.00 and not a frame later
            timer.IsGameTimePaused = true;
        }
        vars.enteredFinalBoss = false;
    });
    timer.OnStart += vars.startActions;
	
	// todo: onsplit stopwatch reset
    
    vars.enteredFinalBoss = false;
    vars.timerModel = new TimerModel { CurrentState = timer }; // to use the undo split method
}

update {
    // if the player loads to a part of the level before the final boss, the final split triggers once they enter the final boss again, this "fixes" that
	// todo: add split timer condition to only do this when a split actually happened recently
    if (current.music == 14 && old.music != 14 && vars.enteredFinalBoss && current.level >= 10 && current.level <= 12) {
        vars.timerModel.UndoSplit();
    }
    
    // "enteredFinalBoss" used by the final split
    if (current.music == 14 && old.music != 14 && current.level >= 10 && current.level <= 12) {
        vars.enteredFinalBoss = true;
    }
    
}

start {
    if (current.level == 1 && current.sublevel == 9 && current.loading){
        timer.IsGameTimePaused = true;
        return true;
    }
}

isLoading {
    return current.loading;
}

split {
    return (current.level == old.level + 1 && current.level != 11 && current.level != 12) 
        || (current.music == -1 && old.music != -1 && vars.enteredFinalBoss && !current.loading && current.level >= 10 && current.level <= 12);
}

reset {
    return current.level == 0 && old.level != 0;
}

exit {
    timer.OnStart -= vars.startActions;
}