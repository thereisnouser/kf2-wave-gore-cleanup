// Wave Gore Cleanup 0.1.1
// Entry point for conventional loading and Safe Mut Loader.
class WaveGoreCleanupMutator extends KFMutator;

var private WaveGoreCleanupRuntime Runtime;

public simulated function bool SafeDestroy()
{
    return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
    Super.PreBeginPlay();

    if (WorldInfo.NetMode == NM_Client)
    {
        return;
    }

    foreach WorldInfo.DynamicActors(class'WaveGoreCleanupRuntime', Runtime)
    {
        if (!Runtime.bDeleteMe)
        {
            break;
        }
        Runtime = None;
    }

    if (Runtime == None)
    {
        Runtime = WorldInfo.Spawn(class'WaveGoreCleanupRuntime');
    }

    if (Runtime == None)
    {
        `log("[Wave Gore Cleanup] Unable to spawn runtime");
        SafeDestroy();
    }
}

public function AddMutator(Mutator Mut)
{
    if (Mut == Self)
    {
        return;
    }

    if (Mut.Class == Class)
    {
        WaveGoreCleanupMutator(Mut).SafeDestroy();
    }
    else
    {
        Super.AddMutator(Mut);
    }
}

static function string GetLocalString(optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2)
{
    return string(class'WaveGoreCleanupRuntime');
}

defaultproperties
{
}
