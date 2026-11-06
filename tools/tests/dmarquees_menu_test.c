#include "../../dmarquees/helpers.h"
#include <assert.h>

int main(void)
{
    assert(menuControlPanel(true, "DC", "dcpanel1.cfg") == eULTRA_DC);
    assert(menuControlPanel(true, "MC", "atarifs.cfg") == eATARI_MC);
    assert(menuControlPanel(true, "MK", "mkwheel.cfg") == eWHEEL_MK);
    assert(menuControlPanel(true, "AC", "atarifs.cfg") == eATARI_AC);
    assert(menuControlPanel(true, "dc", "dcpanel1") == eULTRA_DC);
    assert(menuControlPanel(false, "DC", "dcpanel1.cfg") == ePANEL_NA);
    assert(menuControlPanel(true, "NA", "dcpanel1.cfg") == ePANEL_NA);
    assert(menuControlPanel(true, "unknown", "dcpanel1.cfg") == ePANEL_NA);
    assert(menuControlPanel(true, NULL, "dcpanel1.cfg") == ePANEL_NA);
    assert(menuControlPanel(true, "DC", "allctrlrs.cfg") == ePANEL_NA);
    assert(menuControlPanel(true, "DC", "/profiles/ALLCTRLRS.CFG") == ePANEL_NA);
    assert(menuControlPanel(true, "DC", "allctrlrs") == ePANEL_NA);
    assert(menuControlPanel(true, "DC", "") == ePANEL_NA);
    assert(menuControlPanel(true, "DC", NULL) == ePANEL_NA);
    return 0;
}
