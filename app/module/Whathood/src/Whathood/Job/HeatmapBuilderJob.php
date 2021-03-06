<?php

namespace Whathood\Job;


use Whathood\Entity\NeighborhoodBoundary;
use Whathood\Timer;
use Whathood\Election\PointElectionCollection;
use Whathood\Entity\Neighborhood;

class HeatmapBuilderJob extends \Whathood\Job\AbstractJob
{

    protected $_gridResolution;

    public static function build(array $data) {
        $job = parent::build($data);
        if (empty($job->m()))
            throw new \InvalidArgumentException("must define mapperBuilder");
        if (empty($job->getGridResolution()))
            throw new \InvalidArgumentException("gridResolution may not be empty");
        return $job;
    }

    public function setContent($content) {
        parent::setContent($content);

        if (!array_key_exists('neighborhood_id', $content))
            throw new \InvalidArgumentException("neighborhood_id must be included");
        if (empty($content['neighborhood_id']))
            throw new \InvalidArgumentException("neighborhood_id may not be empty");
    }

    public function execute() {
        $this->infoLog("job ".$this->getName()." started");
        $this->infoLog("grid-resolution: ".rtrim(sprintf("%.8F",$this->getGridResolution()),"0"));
        $neighborhood = $this->m()->neighborhoodMapper()
            ->byId($this->getNeighborhoodId());

        if (!$neighborhood) {
            $str = "must include neighborhood in job content";
            $this->infoLog($str);
            throw new \Whathood\Exception($str);
        }

        $this->infoLog(
            sprintf("neighborhood %s(%s)", $neighborhood->getName(), $neighborhood->getId()));

        $userPolygons = $this->m()->userPolygonMapper()->byNeighborhood($neighborhood);

        if (empty($userPolygons)) {
            $str = sprintf("%s: no user polygons found for neighborhood %s(%s)",
                $this->getName(), $neighborhood->getName(), $neighborhood->getId());
            $this->infoLog($str);
            throw new \Whathood\Exception($str);
        }

        $this->infoLog(
            sprintf("neighborhood %s(%s) num_user_polygons=%s",
                $neighborhood->getName(), $neighborhood->getId(), count($userPolygons)));

        try {
            /* build the border */
            $timer = Timer::start('generate_border');
            $electionCollection = $this->m()->pointElectionMapper()->getCollection(
                $userPolygons,
                $neighborhood->getId(),
                $this->getGridResolution()
            );

            $this->buildAndSaveHeatmapPoints($userPolygons, $neighborhood, $this->getGridResolution());
            $timer->stop();
        }
        catch(\Exception $e) {
            $this->infoLog($e->getMessage());
            $this->infoLog($e->getTraceAsString());
            throw $e;
        }
        $this->infoLog("job finished");
    }

    /**
     * take the user polygons, run a point election, and save the points in the db
     **/
    public function buildAndSaveHeatmapPoints($user_polygons, Neighborhood $n, $grid_resolution) {

        $timer = Timer::start("heatmap_builder");
        $electionCollection = $this->m()->pointElectionMapper()
            ->getCollection(
                $user_polygons,
                $n->getId(),
                $grid_resolution
            );

        $heatmap_points = $electionCollection->heatMapPointsByNeighborhood($n);

        if (!empty($heatmap_points)) {
            $this->m()->heatMapPoint()->deleteByNeighborhood($n);
            $this->m()->heatMapPoint()->savePoints($heatmap_points);
            $this->m()->heatMapPoint()->detach($heatmap_points);
            $this->infoLog(
                sprintf("saved %s heatmap points from %s points elapsed=%s",
                    count($heatmap_points), count($electionCollection->getPointElections()), $timer->elapsedReadableString()
                )
            );
        }
        else
            $this->infoLog("\t\tno heatmap_points generated to save");
        return $heatmap_points;
    }

    public function setHeatmapGridResolution($gridRes) {
        $this->_heatmapGridResolution = $gridRes;
    }

    public function getHeatmapGridResolution() {
        return $this->_heatmapGridResolution;
    }

    public function setGridResolution($gridResolution) {
        $this->_gridResolution = $gridResolution;
    }

    public function getGridResolution() {
        return $this->_gridResolution;
    }

    public function getNeighborhoodId() {
        return $this->getContent()['neighborhood_id'];
    }

    public function __construct(array $data) {
        parent::__construct($data);
    }
}
