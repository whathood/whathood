<?php
namespace Whathood\Controller\Console;

use Whathood\Spatial\PHP\Types\Geometry\MultiPoint as WhMultiPoint;
use Whathood\Controller\BaseController;
use Zend\Json\Json;

/**
 * Handle test point actions from the console
 *
 */
class NeighborhoodPolygonController extends BaseController
{

    /**
     * return geojson representation of test points given either
     *
     *  - neighborhood name and region name
     */
    public function consoleDefaultAction() {
        $nps = $this->m()->neighborhoodPolygonMapper()->fetchAll();
        die( "found ".count($nps));
    }
}
