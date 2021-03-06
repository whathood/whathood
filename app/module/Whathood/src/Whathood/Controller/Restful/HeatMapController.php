<?php
namespace Whathood\Controller\Restful;

use Zend\View\Model\JsonModel;
use CrEOF\Spatial\PHP\Types\Geometry\Point;
use Whathood\Entity\Neighborhood;
use Whathood\Entity\HeatMapPoint;

/**
 * serve restful requests for election points
 */
class HeatMapController extends BaseController {

    public function get($id) {
        die("not yet implemented");
    }

    /**
     * can handle queries of:
     *  - x and y
     */
    public function getListAction() {
        $neighborhood_id = $this->params()->fromRoute('neighborhood_id');

        $neighborhood = $this->m()->neighborhood()->byId($neighborhood_id);
        $heatmap_points = $this->m()->heatMapPoint()->byNeighborhood($neighborhood);
        return new JsonModel(HeatMapPoint::pointsToArray($heatmap_points));
    }

    public function noHeatmapPointsAction() {
        $neighborhoods = $this->m()->heatMapPoint()->neighborhoodsWithNoHeatmapPoints();

        foreach($neighborhoods as $n) {
            print $n->getName();
        }
    }

}
