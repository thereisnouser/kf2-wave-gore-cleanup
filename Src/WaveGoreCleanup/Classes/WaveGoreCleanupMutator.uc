// Wave Gore Cleanup 0.1.0
// Server-side bootstrap: keeps one client-side cleanup helper per player.
// Neither the game mode nor the existing Unofficial KF2 Patch is replaced.
class WaveGoreCleanupMutator extends KFMutator;

function InitMutator(string Options, out string ErrorMessage)
{
    super.InitMutator(Options, ErrorMessage);

    `log("[Wave Gore Cleanup] Mutator initialized (v0.1.0)");

    // Also handles players joining after the match has started.
    SetTimer(1.0, true, 'EnsureClientHelpers');
    EnsureClientHelpers();
}

function EnsureClientHelpers()
{
    local PlayerController PC;
    local WaveGoreCleanupClient Helper;
    local bool bAlreadyPresent;

    if (Role != ROLE_Authority)
    {
        return;
    }

    foreach WorldInfo.AllControllers(class'PlayerController', PC)
    {
        if (PC == None)
        {
            continue;
        }

        bAlreadyPresent = false;
        foreach WorldInfo.AllActors(class'WaveGoreCleanupClient', Helper)
        {
            if (Helper.Owner == PC)
            {
                bAlreadyPresent = true;
                break;
            }
        }

        if (!bAlreadyPresent)
        {
            Helper = Spawn(class'WaveGoreCleanupClient', PC);
            if (Helper != None)
            {
                `log("[Wave Gore Cleanup] Client helper created for" @ PC);
            }
        }
    }
}

defaultproperties
{
}
