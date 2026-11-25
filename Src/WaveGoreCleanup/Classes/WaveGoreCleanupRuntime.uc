// Wave Gore Cleanup 0.1.1
// Server-only controller shared by conventional loading and Safe Mut Loader.
class WaveGoreCleanupRuntime extends Info;

public event PostBeginPlay()
{
    local WaveGoreCleanupRuntime OtherRuntime;

    Super.PostBeginPlay();

    if (WorldInfo.NetMode == NM_Client)
    {
        return;
    }

    foreach WorldInfo.DynamicActors(class'WaveGoreCleanupRuntime', OtherRuntime)
    {
        if (OtherRuntime != Self && !OtherRuntime.bDeleteMe)
        {
            Destroy();
            return;
        }
    }

    SetTimer(1.0, true, 'EnsureClientHelpers');
    EnsureClientHelpers();
    `log("[Wave Gore Cleanup] Runtime initialized (v0.1.1)");
}

function EnsureClientHelpers()
{
    local KFPlayerController PC;
    local WaveGoreCleanupClient Helper;
    local bool bAlreadyPresent;

    if (Role != ROLE_Authority)
    {
        return;
    }

    foreach WorldInfo.AllControllers(class'KFPlayerController', PC)
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
    bNoDelete=false
    RemoteRole=ROLE_None
}
